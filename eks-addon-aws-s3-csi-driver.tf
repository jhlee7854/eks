data "aws_iam_policy_document" "AmazonEKS_S3_CSI_DriverAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:s3-csi-*"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_cluster.arn]
    }
  }
}

resource "aws_iam_role" "AmazonEKS_S3_CSI_DriverRole" {
  name               = "${var.project_name}-${var.env}-AmazonEKS_S3_CSI_DriverRole"
  assume_role_policy = data.aws_iam_policy_document.AmazonEKS_S3_CSI_DriverAssumeRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_EBS_CSI_DriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3CSIDriverPolicy"
  role       = aws_iam_role.AmazonEKS_S3_CSI_DriverRole.name
}

resource "aws_eks_addon" "aws-mountpoint-s3-csi-driver" {
  depends_on    = [aws_eks_node_group.app_node_group]
  cluster_name  = aws_eks_cluster.eks_cluster.name
  addon_name    = "aws-mountpoint-s3-csi-driver"
  addon_version = "v1.1.0-eksbuild.1"
}
