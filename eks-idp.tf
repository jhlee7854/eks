resource "aws_eks_identity_provider_config" "oidc" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  oidc {
    client_id                     = "sts.amazonaws.com"
    identity_provider_config_name = aws_eks_cluster.eks_cluster.name
    issuer_url                    = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
  }
}

data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
