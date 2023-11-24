variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "eks_version" {
  type = string
  # https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-version-standard.html
  default = "1.27"
}

variable "eks_optimazed_ami_id" {
  type = string
  # https://ap-northeast-2.console.aws.amazon.com/systems-manager/parameters/aws/service/eks/optimized-ami/1.27/amazon-linux-2/recommended/image_id/description
  default = "ami-066d97e5af88c37a2"
}

variable "eks_public_access_cidrs" {
  type = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "app_node_group_launch_template_name" {
  type = string
}

variable "app_node_group_launch_template_version" {
  type = string
}
