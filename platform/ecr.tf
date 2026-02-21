# ECR Repositories for workshop projects
module "ecr" {
  source = "./modules/ecr"
  count  = length(var.projects) > 0 ? 1 : 0

  project_names = var.projects
}
