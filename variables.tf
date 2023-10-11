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
  default = "1.28"
}

variable "eks_public_access_cidrs" {
  type = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "app_node_group_launch_template_id" {
  type = string
}

variable "app_node_group_launch_template_version" {
  type = string
}
