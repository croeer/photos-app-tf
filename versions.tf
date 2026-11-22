terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.29.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}
