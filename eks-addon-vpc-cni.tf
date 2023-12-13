data "aws_iam_policy_document" "AmazonEKSVPCCNIAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_cluster.arn]
    }
  }
}

resource "aws_iam_role" "AmazonEKSVPCCNIRole" {
  name               = "${var.project_name}-${var.env}-AmazonEKSVPCCNIRole"
  assume_role_policy = data.aws_iam_policy_document.AmazonEKSVPCCNIAssumeRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.AmazonEKSVPCCNIRole.name
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on                  = [aws_eks_cluster.eks_cluster, aws_iam_openid_connect_provider.eks_cluster, aws_iam_role.AmazonEKSVPCCNIRole]
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.12.6-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  preserve                    = true
}
