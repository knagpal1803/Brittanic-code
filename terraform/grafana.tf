resource "grafana_organization" "main_org" {
  name         = "Main Org."
  admin_user   = "admin"
  create_users = false
}

resource "grafana_data_source" "prometheus" {
  org_id     = grafana_organization.main_org.org_id
  type       = "prometheus"
  name       = "Prometheus-Docker"
  url        = "http://prometheus:9090" # Uses container name inside monitoring_net
  is_default = true

  depends_on = [docker_container.grafana, docker_container.prometheus]
}

resource "grafana_folder" "infra_folder" {
  org_id = grafana_organization.main_org.org_id
  title  = "Infrastructure Metrics"

  depends_on = [docker_container.grafana]
}

resource "grafana_contact_point" "email_alerts" {
  name   = "Email Team Platform"
  org_id = grafana_organization.main_org.org_id

  email {
    addresses    = ["devops-team@example.com"]
    single_email = true
  }
}

resource "grafana_notification_policy" "alert_routing" {
  org_id = grafana_organization.main_org.org_id

  receiver = grafana_contact_point.email_alerts.name

  policy {
    receiver = grafana_contact_point.email_alerts.name
    matchers {
      label = "severity"
      value = "critical"
    }
  }
}
