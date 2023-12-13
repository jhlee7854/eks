data "aws_iam_policy_document" "AmazonEKSEBSCSIDriverAssumeRolePolicy" {
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
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_cluster.arn]
    }
  }
}

resource "aws_iam_role" "AmazonEKSEBSCSIDriverRole" {
  name               = "${var.project_name}-${var.env}-AmazonEKSEBSCSIDriverRole"
  assume_role_policy = data.aws_iam_policy_document.AmazonEKSEBSCSIDriverAssumeRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.AmazonEKSEBSCSIDriverRole.name
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  depends_on                  = [aws_eks_node_group.app_node_group, aws_iam_openid_connect_provider.eks_cluster, aws_iam_role.AmazonEKSEBSCSIDriverRole]
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.25.0-eksbuild.1"
  service_account_role_arn    = aws_iam_role.AmazonEKSEBSCSIDriverRole.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  preserve                    = true

  timeouts {
    create = "10m"
  }
}
