resource "aws_eks_addon" "coredns" {
  depends_on   = [aws_eks_node_group.app_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"
  # configuration_values = "{\"replicaCount\":2,\"resources\":{\"limits\":{\"memory\":\"170Mi\"},\"requests\":{\"cpu\":\"100m\",\"memory\":\"70Mi\"}}}"
  configuration_values = jsonencode({
    replicaCount = 2
    resources = {
      limits = {
        memory = "170Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "70Mi"
      }
    }
  })
  addon_version = "v1.10.1-eksbuild.1"
}
