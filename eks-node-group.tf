resource "aws_iam_role" "AmazonEKSNodeGroupRole" {
  name = "${var.project_name}-${var.env}-AmazonEKSNodeGroupRole"

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

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.AmazonEKSNodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.AmazonEKSNodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.AmazonEKSNodeGroupRole
}

locals {
  eks-app-node-userdata = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash -xe
sudo /etc/eks/bootstrap.sh '${aws_eks_cluster.eks_cluster.name}' --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority[0].data}'

--==MYBOUNDARY==--
USERDATA
}

# resource "aws_security_group_rule" "allnodes_sg_ingress" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   source_security_group_id = aws_security_group.cluster_sg.id
#   security_group_id        = aws_security_group.allnodes-sg.id
# }

# resource "aws_security_group_rule" "allnodes_sg_egress" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.allnodes-sg.id
# }

resource "aws_launch_template" "app_node" {
  instance_type = "t3.medium"
  key_name      = "mountpoint-s3"
  name          = "app_node_launch_template"
  image_id      = var.eks_optimazed_ami_id
  user_data     = base64encode(local.eks-app-node-userdata)
  # vpc_security_group_ids = [aws_security_group.allnodes-sg.id]
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
  node_role_arn   = aws_iam_role.AmazonEKSNodeGroupRole.arn
  subnet_ids = [
    aws_subnet.private_subnet_01.id,
    aws_subnet.private_subnet_02.id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 3
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
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
