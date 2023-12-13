data "aws_iam_policy_document" "AmazonEKSS3CSIDriverAssumeRolePolicy" {
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

resource "aws_iam_role" "AmazonEKSS3CSIDriverRole" {
  name               = "${var.project_name}-${var.env}-AmazonEKSS3CSIDriverRole"
  assume_role_policy = data.aws_iam_policy_document.AmazonEKSS3CSIDriverAssumeRolePolicy.json
}

resource "aws_iam_policy" "AmazonEKSS3CSIDriverPolicy" {
  name        = "${var.project_name}-${var.env}-AmazonEKSS3CSIDriverPolicy"
  description = "${var.project_name}-${var.env}-AmazonEKSS3CSIDriverPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MountpointFullBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::eks-share"
        ]
      },
      {
        Sid    = "MountpointFullObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::eks-share/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSS3CSIDriverPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSS3CSIDriverPolicy.arn
  role       = aws_iam_role.AmazonEKSS3CSIDriverRole.name
}

resource "aws_eks_addon" "aws-mountpoint-s3-csi-driver" {
  depends_on    = [aws_eks_node_group.app_node_group]
  cluster_name  = aws_eks_cluster.eks_cluster.name
  addon_name    = "aws-mountpoint-s3-csi-driver"
  addon_version = "v1.1.0-eksbuild.1"
}
