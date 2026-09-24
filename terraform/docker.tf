resource "docker_volume" "grafana_storage" {
  name = "grafana-storage"
}
resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = false
}

resource "docker_container" "grafana" {
  image = docker_image.grafana.image_id
  name  = "grafana"

  ports {
    internal = 3000
    external = 3000
  }

  # Set initial admin credentials
  env = var.credentials

  volumes {
    volume_name    = docker_volume.grafana_storage.name
    container_path = "/var/lib/grafana"
  }
}
