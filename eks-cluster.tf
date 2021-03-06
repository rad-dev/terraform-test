module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.18"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = "test"
    GithubRepo  = "rad-dev"
    GithubOrg   = "rad-dev/terraform-test"
  }

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-storage-group"
      instance_type                 = "t2.small"
      additional_userdata           = "echo storage group for storage tasks e.g. databases"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_storage_group_mgmt.id]
      kubelet_extra_args            = "--node-labels=hosttype=storage"  
    },
    {
      name                          = "worker-cpu-group"
      instance_type                 = "t2.small"
      additional_userdata           = "echo gpu group for cpu-intensive tasks"
      additional_security_group_ids = [aws_security_group.worker_cpu_group_mgmt.id]
      asg_desired_capacity          = 1
      kubelet_extra_args            = "--node-labels=hosttype=cpu"  
    },
    {
      name                          = "worker-gpu-group"
      instance_type                 = "t2.small"
      additional_userdata           = <<EOT
                distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && \
                curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - && \
                curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list && \
                sudo apt-get update && sudo apt-get install -y nvidia-docker2 && \
                sudo systemctl restart docker
                EOT
      additional_security_group_ids = [aws_security_group.worker_gpu_group_mgmt.id]
      asg_desired_capacity          = 1
      kubelet_extra_args            = "--node-labels=hosttype=gpu"  
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
