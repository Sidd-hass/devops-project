variable "civo_token" {
  description = "Civo API token"
  type        = string
  default     = "" # leave blank in repo; set via terraform.tfvars or env
  sensitive   = true
}

variable "civo_region" {
  description = "Civo region (e.g. LON1, NYC1, SGP1)"
  type        = string
  default     = "LON1"
}

variable "cluster_name" {
  type    = string
  default = "devops-assignment-cluster"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_size" {
  type    = string
  default = "g4s.kube.small"
}
