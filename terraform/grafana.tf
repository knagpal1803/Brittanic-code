resource "grafana_folder" "metrics_folder" {
  title      = "Infrastructure Metrics"
  depends_on = [docker_container.grafana]
}

resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "Local Prometheus"
  url        = "http://localhost:9090"
  is_default = true
  depends_on = [docker_container.grafana]
}
