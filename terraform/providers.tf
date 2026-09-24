terraform {
  required_version = ">= 1.9.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "grafana" {
  url  = "http://localhost:3000"
  auth = var.AUTH_VAR
}
