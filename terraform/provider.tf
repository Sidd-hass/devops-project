terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "~> 1.1"
    }
  }
  required_version = ">= 1.3.0"
}

provider "civo" {
  token  = var.civo_token  # or rely on env var CIVO_TOKEN
  region = var.civo_region # e.g., "LON1" or "NYC1" or whichever region you choose
}
