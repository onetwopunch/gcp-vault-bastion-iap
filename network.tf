#
# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This file contains the networking bits.
#

# Address for NATing
resource "google_compute_address" "vault-nat" {
  count   = 2
  project = "${var.project_id}"
  name    = "vault-nat-external-${count.index}"
  region  = "${var.region}"

  depends_on = ["google_project_service.service"]
}

# Create a NAT router so the nodes can reach the public Internet
resource "google_compute_router" "vault-router" {
  name    = "vault-router"
  project = "${var.project_id}"
  region  = "${var.region}"
  network = "${google_compute_network.vault-network.self_link}"

  bgp {
    asn = 64514
  }

  depends_on = ["google_project_service.service"]
}

# NAT on the main subnetwork
resource "google_compute_router_nat" "vault-nat" {
  name    = "vault-nat-1"
  project = "${var.project_id}"
  router  = "${google_compute_router.vault-router.name}"
  region  = "${var.region}"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = ["${google_compute_address.vault-nat.*.self_link}"]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = "${google_compute_subnetwork.vault-subnet.self_link}"
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }

  depends_on = ["google_project_service.service"]
}

resource "google_compute_network" "vault-network" {
  project = "${var.project_id}"

  name                    = "vault-network"
  auto_create_subnetworks = false

  depends_on = ["google_project_service.service"]
}

resource "google_compute_subnetwork" "vault-subnet" {
  project = "${var.project_id}"

  name                     = "vault-subnet"
  region                   = "${var.region}"
  ip_cidr_range            = "${var.network_subnet_cidr_range}"
  network                  = "${google_compute_network.vault-network.self_link}"
  private_ip_google_access = true

  depends_on = ["google_project_service.service"]
}

# Data source for list of google IPs
data "google_compute_lb_ip_ranges" "ranges" {
  # hashicorp/terraform#20484 prevents us from depending on the service
}

# Allow the load balancers to talk to query the health - this happens over the
# legacy proxied health port over HTTP because the health checks do not support
# HTTPS.
resource "google_compute_firewall" "allow-lb-healthcheck" {
  project = "${var.project_id}"
  name    = "vault-allow-lb-healthcheck"
  network = "${google_compute_network.vault-network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["${var.vault_port}"]
  }

  source_ranges = [
    "${data.google_compute_lb_ip_ranges.ranges.network}",
    "${data.google_compute_lb_ip_ranges.ranges.http_ssl_tcp_internal}",
  ]

  target_service_accounts = ["${google_service_account.vault-admin.email}"]

  depends_on = ["google_project_service.service"]
}

# Allow Vault nodes to talk internally on the Vault ports.
resource "google_compute_firewall" "allow-internal" {
  project = "${var.project_id}"
  name    = "vault-allow-internal"
  network = "${google_compute_network.vault-network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["${var.vault_port}-${var.vault_port + 1}"]
  }

  source_service_accounts = [
    "${google_service_account.bastion.email}",
    "${google_service_account.vault-admin.email}",
    "${var.allowed_service_accounts}",
  ]
  target_service_accounts = ["${google_service_account.vault-admin.email}"]
  depends_on = ["google_project_service.service"]
}

# Allow SSHing into machines tagged "allow-ssh"
resource "google_compute_firewall" "allow-ssh" {
  project = "${var.project_id}"
  name    = "vault-allow-ssh"
  network = "${google_compute_network.vault-network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH only from IAP
  source_ranges = ["35.235.240.0/20"]
  target_service_accounts = ["${google_service_account.bastion.email}"]

  depends_on = ["google_project_service.service"]
}
