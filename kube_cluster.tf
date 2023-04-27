data "aws_availability_zones" "available" {
  state = "available"
}
module "vpc2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"

  #  azs             = data.aws_availability_zones.available.names[*]
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name_cluster}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name_cluster}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
  tags = {
    Environment                                   = "dev"
    "kubernetes.io/cluster/$(local.name_cluster)" = "shared"
  }


}
resource "aws_iam_role" "main2" {
  name               = "${local.name_cluster}-role"
  assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
{
  "Effect": "Allow",
  "Principal": {
  "Service": "eks.amazonaws.com"
},
"Action": "sts:AssumeRole"
}
]
}
POLICY
}


data "aws_caller_identity" "main" {}

locals {

  name_cluster = "education-eks"
}

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${local.name_cluster}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "eks" {
  cluster_name   = "${local.name_cluster}"
  source         = "terraform-aws-modules/eks/aws"
  version        = "19.13.1"
  subnet_ids     = module.vpc2.private_subnets
  vpc_id         = module.vpc2.vpc_id
  iam_role_arn   = aws_iam_role.main2.arn
  cluster_addons = {
    aws-ebs-csi-driver = {
      #      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.main.account_id}:role/${local.name_cluster}-ebs-csi-controller"
      #      addon_version = "v1.13.0-eksbuild.2"
      #      resolve_conflicts="PRESERVE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
      most_recent              = true
    }
  }
  eks_managed_node_groups = {
    test = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"
    }
  }
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]


}