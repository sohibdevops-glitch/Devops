# MongoDB (hosted in MongoDB Atlas)

resource "mongodbatlas_project" "project" {
  for_each = local.env_vars.sub_envs

  name   = "${local.prefix.mongodb_project}-${each.key}"
  org_id = local.mongodbatlas_organization_id

  lifecycle {
    ignore_changes = [ teams ]
  }
}

module "mongodb_px" {
  source = "./modules/mongodb"

  for_each = local.env_vars.sub_envs

  mongodb_project = {
    organization_id = local.mongodbatlas_organization_id
    project_id      = mongodbatlas_project.project[each.key].id
  }

  cluster_name    = "${local.prefix.mongodb_cluster}-px-${each.key}"
  mongodb_version = "8.0"
  cloud_provider  = "AZURE"
  cloud_region    = local.env_vars.sub_envs[each.key].mongodb.cloud_region
  node_count      = local.env_vars.sub_envs[each.key].mongodb.node_count
  instance_size   = local.env_vars.sub_envs[each.key].mongodb.instance_size

  depends_on = [mongodbatlas_project.project]
}

module "mongodb_up" {
  source = "./modules/mongodb"

  for_each = local.env_vars.sub_envs

  mongodb_project = {
    organization_id = local.mongodbatlas_organization_id
    project_id      = mongodbatlas_project.project[each.key].id
  }

  cluster_name    = "${local.prefix.mongodb_cluster}-up-${each.key}"
  mongodb_version = "8.0"
  cloud_provider  = "AZURE"
  cloud_region    = local.env_vars.sub_envs[each.key].mongodb.cloud_region
  node_count      = local.env_vars.sub_envs[each.key].mongodb.node_count
  instance_size   = local.env_vars.sub_envs[each.key].mongodb.instance_size

  depends_on = [mongodbatlas_project.project]
}

module "mongodb_bp" {
  source = "./modules/mongodb"

  for_each = local.env_vars.sub_envs

  mongodb_project = {
    organization_id = local.mongodbatlas_organization_id
    project_id      = mongodbatlas_project.project[each.key].id
  }

  cluster_name    = "${local.prefix.mongodb_cluster}-bp-${each.key}"
  mongodb_version = "8.0"
  cloud_provider  = "AZURE"
  cloud_region    = local.env_vars.sub_envs[each.key].mongodb.cloud_region
  node_count      = local.env_vars.sub_envs[each.key].mongodb.node_count
  instance_size   = local.env_vars.sub_envs[each.key].mongodb.instance_size

  depends_on = [mongodbatlas_project.project]
}

module "mongodb_project_private_endpoint" {
  source = "./modules/mongodbProjectPrivateEnpoint"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = data.azurerm_resource_group.main.name
    location            = data.azurerm_resource_group.main.location
    tags                = local.tags
  }

  private_endpoint = {
    subnet_id                       = azurerm_subnet.private_endpoints.id
    pep_name                        = "mdb-${local.prefix.mongodb_project}-${each.key}-endpoint"
    private_connection_resource_id  = local.env_vars.sub_envs[each.key].mongodb.private_connection_resource_id
    private_service_connection_name = local.env_vars.sub_envs[each.key].mongodb.private_service_connection_name
  }

  depends_on = [mongodbatlas_project.project]
}
