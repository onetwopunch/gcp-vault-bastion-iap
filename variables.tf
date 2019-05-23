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
#
# Project
# --------------------
variable project_id {
  type = "string"

  description = <<EOF
ID of the project in which to create resources and add IAM bindings.
EOF
}

variable project_services {
  type = "list"

  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]

  description = <<EOF
List of services to enable on the project where Vault will run. These services
are required in order for this Vault setup to function.

To disable, set to the empty list []. You may want to disable this if the
services have already been enabled and the current user does not have permission
to enable new services.
EOF
}

variable region {
  type    = "string"
  default = "us-east4"

  description = <<EOF
Region in which to create resources.
EOF
}

#
#
# GCS
# --------------------

variable storage_bucket_name {
  type    = "string"
  default = ""

  description = <<EOF
Name of the Google Cloud Storage bucket for the Vault backend storage. This must
be globally unique across of of GCP. If left as the empty string, this will
default to: "<project-id>-vault-data".
EOF
}

variable storage_bucket_location {
  type    = "string"
  default = "us"

  description = <<EOF
Location for the multi-regional Google Cloud Storage bucket in which Vault data
will be stored. Valid values include:

  - asia
  - eu
  - us
EOF
}

variable storage_bucket_force_destroy {
  type    = "string"
  default = false

  description = <<EOF
Set to true to force deletion of backend bucket on `terraform destroy`.
EOF
}

#
#
# IAM
# --------------------

variable service_account_name {
  type    = "string"
  default = "vault-admin"

  description = <<EOF
Name of the Vault service account.
EOF
}

variable service_account_project_iam_roles {
  type = "list"

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]

  description = <<EOF
List of IAM roles for the Vault admin service account to function. If you need
to add additional roles, update `service_account_project_additional_iam_roles`
instead.
EOF
}

variable service_account_project_additional_iam_roles {
  type    = "list"
  default = []

  description = <<EOF
List of custom IAM roles to add to the project.
EOF
}

variable service_account_storage_bucket_iam_roles {
  type = "list"

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]

  description = <<EOF
List of IAM roles for the Vault admin service account to have on the storage
bucket.
EOF
}

#
#
# KMS
# --------------------

variable kms_keyring {
  type = "string"

  description = <<EOF
Name of the Cloud KMS KeyRing for asset encryption.
EOF
}

variable kms_crypto_key {
  type    = "string"
  default = "vault-init"

  description = <<EOF
The name of the Cloud KMS Key used for encrypting initial TLS certificates and
for configuring Vault auto-unseal.
EOF
}

variable kms_protection_level {
  type    = "string"
  default = "software"

  description = <<EOF
The protection level to use for the KMS crypto key.
EOF
}

#
#
# Networking
# --------------------

variable network_subnet_cidr_range {
  type    = "string"
  default = "10.127.0.0/20"

  description = <<EOF
CIDR block range for the subnet.
EOF
}

variable internal_lb_ip {
  type    = "string"
  default = "10.127.13.37"

  description = <<EOF
RFC 1918 Address for internal load balancer
EOF
}

#
#
# TLS
# --------------------
variable vault_tls_bucket {
  type = "string"
  default = ""
  description = <<EOF
Use this bucket to store your own TLS files, if you do not want this to generate them.
By default this module expects the following files at the root of the bucket, but these
can be overriden:
- `ca.crt`: Root CA public certificate
- `vault.crt`: Vault server public certificate, signed by the ca.crt
- `vault.key.enc` Vault server certificate private key, encrypted with the kms key provided.
EOF
}

variable vault_ca_cert_filename {
  type = "string"
  default = "ca.crt"
  description = <<EOF
GCS object path within the vault_tls_bucket. This is the root CA certificate.
Default: ca.crt
EOF
}

variable vault_tls_key_filename {
  type = "string"
  default = "vault.key.enc"
  description = <<EOF
Encrypted GCS object path within the vault_tls_bucket. This is the Vault TLS private key.
Default: vault.key.enc
EOF
}

variable vault_tls_cert_filename {
  type = "string"
  default = "vault.crt"
  description = <<EOF
GCS object path within the vault_tls_bucket. This is the vault server certificate.
Default: vault.crt
EOF
}

variable tls_ca_subject {
  description = "The `subject` block for the root CA certificate."
  type        = "map"

  default = {
    common_name         = "Example Inc. Root"
    organization        = "Example, Inc"
    organizational_unit = "Department of Certificate Authority"
    street_address      = ["123 Example Street"]
    locality            = "The Intranet"
    province            = "CA"
    country             = "US"
    postal_code         = "95559-1227"
  }
}

variable tls_dns_names {
  description = "List of DNS names added to the Vault server self-signed certificate"
  type        = "list"
  default     = ["vault.example.net"]
}

variable tls_ips {
  description = "List of IP addresses added to the Vault server self-signed certificate"
  type        = "list"
  default     = ["127.0.0.1"]
}

variable tls_cn {
  description = "The TLS Common Name for the TLS certificates"
  default     = "vault.example.net"
}

variable tls_ou {
  description = "The TLS Organizational Unit for the TLS certificate"
  default     = "IT Security Operations"
}


#
#
# Vault
# --------------------

variable allowed_service_accounts {
  type    = "list"
  default = []

  description = <<EOF
Service account emails that are allowed to communicate to Vault over HTTPS on
port 8200. By default, only the bastion and Vault nodes themselves are permitted.
EOF
}

variable vault_args {
  type    = "string"
  default = ""

  description = <<EOF
Additional command line arguments passed to Vault server/
EOF
}

variable vault_instance_labels {
  type    = "map"
  default = {}

  description = <<EOF
Labels to apply to the Vault instances.
EOF
}

variable vault_instance_metadata {
  type    = "map"
  default = {}

  description = <<EOF
Additional metadata to add to the Vault instances.
EOF
}

variable vault_instance_tags {
  type    = "list"
  default = []

  description = <<EOF
Additional tags to apply to the instances. Note "allow-ssh" and "allow-vault"
will be present on all instances.
EOF
}

variable vault_log_level {
  type    = "string"
  default = "warn"

  description = <<EOF
Log level to run Vault in. See the Vault documentation for valid values.
EOF
}

variable vault_min_num_servers {
  type    = "string"
  default = "2"

  description = <<EOF
Minimum number of Vault server nodes in the autoscaling group. The group will
not have less than this number of nodes.
EOF
}

variable vault_machine_type {
  type    = "string"
  default = "n1-standard-1"

  description = <<EOF
Machine type to use for Vault instances.
EOF
}

variable vault_max_num_servers {
  type    = "string"
  default = "7"

  description = <<EOF
Maximum number of Vault server nodes to run at one time. The group will not
autoscale beyond this number.
EOF
}

variable vault_port {
  type    = "string"
  default = "8200"

  description = <<EOF
Numeric port on which to run and expose Vault. This should be a high-numbered
port, since Vault does not run as a root user and therefore cannot bind to
privledged ports like 80 or 443. The default is 8200, the standard Vault port.
EOF
}

variable vault_tls_disable_client_certs {
  type    = "string"
  default = false

  description = <<EOF
Use and expect client certificates. You may want to disable this if users will
not be authenticating to Vault with client certificates.
EOF
}

variable vault_ui_enabled {
  type    = "string"
  default = true

  description = <<EOF
Controls whether the Vault UI is enabled and accessible.
EOF
}

variable vault_version {
  type    = "string"
  default = "1.1.2"

  description = <<EOF
Version of vault to install. This version must be 1.0+ and must be published on
the HashiCorp releases service.
EOF
}
