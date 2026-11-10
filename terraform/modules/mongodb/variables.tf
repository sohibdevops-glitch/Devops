variable "mongodb_project" {
  type = object({
    organization_id     = string
    project_id          = string
  })
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster used by the application"
}

variable "mongodb_version" {
  type        = string
  description = "Major version of MongoDB to be used for the cluster"
}

variable "cloud_provider" {
  type        = string
  description = "The cloud service provider used by MongoDB Atlas"
}

variable "cloud_region" {
  type        = string
  description = "The region in the cloud provider used to store the  by MongoDB Atlas"
}

variable "instance_size" {
  type        = string
  description = "Hardware specs for instance size"
}

variable "node_count" {
  type        = string
  description = "Number of nodes to deploy to the region"
}