resource "docker_network" "monitoring_net" {
  name = "monitoring_net"
}

resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id
  networks_advanced {
    name = docker_network.monitoring_net.name
  }
  ports {
    internal = 9090
    external = 9090
  }
}

resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id
  networks_advanced {
    name = docker_network.monitoring_net.name
  }
  ports {
    internal = 3000
    external = 3000
  }
  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=strongpassword123",
    "GF_USERS_ALLOW_SIGN_UP=false"
  ]
}
