#data "aws_eks_cluster" "default"{
#  name = aws_eks_cluster.main.name
#}
#data "aws_eks_cluster_auth" "default" {
#  name = aws_eks_cluster.main.name
#}
#
#
#provider "kubernetes" {
#  host = data.aws_eks_cluster.default.endpoint
#
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#  token = data.aws_eks_cluster_auth.default.token
#}
#
#provider "helm" {
#  kubernetes {
#    host = data.aws_eks_cluster.default.endpoint
#    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#    token = data.aws_eks_cluster_auth.default.token
#  }
#
#}
#resource "helm_release" "app-2048" {
#  chart = "${path.module}/helm/2048"
#  name  = "app-2048-helm"
#}




