output "project_id" {
  value = module.network-dev-sharedvpc.project_id
}

output "subnets" {
  value = module.dev-vpc.subnets_self_links
}
