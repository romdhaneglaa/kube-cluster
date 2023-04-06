resource "aws_iam_role" "nodegroup" {
  name               = "${local.cluster_name}-node_group_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodegroup.name
}
resource "aws_iam_role_policy_attachment" "node_group_CNI_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodegroup.name
}
resource "aws_iam_role_policy_attachment" "node_group_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodegroup.name
}

resource "aws_security_group" "node_group_sg" {
  name   = "${local.cluster_name}_worker_sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "-1"
  }
  ingress {
    from_port = 1025
    to_port   = 65535
    protocol  = "tcp"
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }

  tags = {
    Name                                                  = "${local.cluster_name}_npode_sg"
    "kubernetes.io/cluster/${local.cluster_name}-cluster" = "owned"
  }


}

resource "aws_eks_node_group" "main" {
  node_group_name = "${local.cluster_name}-node_group"
  cluster_name    = local.cluster_name
  node_role_arn   = aws_iam_role.nodegroup.arn
  subnet_ids      = module.vpc.private_subnets


  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
}