output "vm_to_provision" {
  value = google_compute_instance.vm.name
}

output "vm_to_provision_zone" {
  value = google_compute_instance.vm.zone
}

output "project_id" {
  value = module.esa-dev-app.project_id
}
