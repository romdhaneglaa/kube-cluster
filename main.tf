data "aws_availability_zones" "available" {
  state = "available"

}

locals {
  cluster_name = "education-eks"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names[*]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
  tags = {
    Environment                                   = "dev"
    "kubernetes.io/cluster/$(local.cluster_name)" = "shared"
  }


}

resource "aws_iam_role" "main" {
  name = "${local.cluster_name}-role"
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
resource "aws_iam_role_policy_attachment" "cluster_eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "cluster_eks_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.main.name
}

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.main.arn
  vpc_config {
    subnet_ids = module.vpc.private_subnets
    endpoint_public_access = true
    public_access_cidrs = ["0.0.0.0/0"]
  }

}








