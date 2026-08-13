resource "mongodbatlas_advanced_cluster" "cluster" {
  project_id                     = var.mongodb_project.project_id
  name                           = var.cluster_name
  cluster_type                   = "REPLICASET"
  backup_enabled                 = true
  pit_enabled                    = true
  mongo_db_major_version         = var.mongodb_version
  termination_protection_enabled = true

  # to avoid destroying clusters once they are created (e.g. renaming cluster would destroy and create)
  lifecycle {
    prevent_destroy = true
  }

  replication_specs {
    region_configs {
      provider_name = var.cloud_provider
      region_name   = var.cloud_region
      # 7 is the highest priority and this value it's only relevant if using multi-region
      priority = 7

      electable_specs {
        instance_size = var.instance_size
        node_count    = var.node_count
      }

      auto_scaling {
        compute_enabled            = false
        disk_gb_enabled            = false
        compute_max_instance_size  = null
        compute_min_instance_size  = null
        compute_scale_down_enabled = false
      }
    }
  }
}
