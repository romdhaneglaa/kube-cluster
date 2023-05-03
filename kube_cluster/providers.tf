terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

  }

  required_version = ">= 1.2.0"
}



provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name,"--region","us-east-1"]
  }
}

#data "aws_eks_cluster" "default"{
#  name = module.eks.cluster_name
#}
#data "aws_eks_cluster_auth" "default" {
#  name = module.eks.cluster_name
#}
#provider "kubernetes" {
#  host = module.eks.cluster_endpoint
#
#  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
##  token = data.aws_eks_cluster_auth.default.token
#}



provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name,"--region","us-east-1"]
    }
  }
}




