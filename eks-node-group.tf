resource "aws_iam_role" "iam_role_eks_node_group" {
  name = "${var.project_name}-${var.env}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy" "iam_role_policy_s3" {
  name = "s3_policy"
  role = aws_iam_role.iam_role_eks_node_group.id

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

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.iam_role_eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.iam_role_eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.iam_role_eks_node_group.name
}

locals {
  eks-app-node-userdata = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash -xe
wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
sudo yum install -y ./mount-s3.rpm
mkdir -p ~/mnt/s3
mount-s3 arn:aws:s3:ap-northeast-2:318374019075:eks-share ~/mnt/s3

--==MYBOUNDARY==--
USERDATA
}

resource "aws_launch_template" "app_node" {
  instance_type          = "t3.medium"
  key_name               = "mountpoint-s3"
  name                   = "app_node_launch_template"
  image_id               = "ami-09af799f87c7601fa"
  user_data              = base64encode(local.eks-app-node-userdata)
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "app-node"
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "app_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "app-node-group"
  node_role_arn   = aws_iam_role.iam_role_eks_node_group.arn
  subnet_ids = [
    aws_subnet.private_subnet_01.id,
    aws_subnet.private_subnet_02.id
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.app_node.id
    version = aws_launch_template.app_node.latest_version
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy.iam_role_policy_s3
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
