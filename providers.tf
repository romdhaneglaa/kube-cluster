terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    kustomization = {
      source  = "kbst/kustomize"
      version = "0.2.0-beta.3"

    }

  }

  required_version = ">= 1.2.0"
}


provider "kustomization" {}


provider "aws" {
  region = "us-east-1"
}

