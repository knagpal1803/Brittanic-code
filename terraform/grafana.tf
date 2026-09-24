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

resource "grafana_dashboard" "system_metrics" {
  org_id = grafana_organization.main_org.org_id
  folder = grafana_folder.infra_folder.id

  config_json = jsonencode({
    id            = null
    uid           = "sys-metrics-docker"
    title         = "Infrastructure Resource Usage"
    tags          = ["templated", "infrastructure"]
    style         = "dark"
    timezone      = "browser"
    schemaVersion = 38
    panels = [
      {
        id    = 1
        type  = "timeseries"
        title = "CPU Utilization"
        gridPos = { h = 8, w = 12, x = 0, y = 0 }
        targets = [
          {
            datasource = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
            expr       = "100 - (avg(rate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)"
            refId      = "A"
          }
        ]
      },
      {
        id    = 2
        type  = "timeseries"
        title = "Memory Utilization"
        gridPos = { h = 8, w = 12, x = 12, y = 0 }
        targets = [
          {
            datasource = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
            expr       = "100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))"
            refId      = "A"
          }
        ]
      }
    ]
  })
}
resource "grafana_rule_group" "resource_alerts" {
  org_id           = grafana_organization.main_org.org_id
  name             = "Resource Usage Checks"
  folder_uid       = grafana_folder.infra_folder.uid
  interval_seconds = 60

  rule {
    name           = "High CPU Usage Alert"
    condition      = "B" 
    for            = "2m"
    exec_err_state = "Alerting"
    no_data_state  = "NoData"

    labels = {
      severity = "critical"
    }


    data {
      ref_id          = "A"
      datasource_uid  = grafana_data_source.prometheus.uid
      query_type      = ""
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        expr         = "100 - (avg(rate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)"
        intervalMs   = 1000
        maxDataPoints = 43200
        refId        = "A"
      })
    }

    data {
      ref_id          = "B"
      datasource_uid  = "-100"
      query_type      = ""
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [
          {
            evaluator = { params = [80], type = "gt" }
            operator  = { type = "and" }
            query     = { params = ["A"] }
            reducer   = { params = [], type = "last" }
            type      = "query"
          }
        ]
        refId = "B"
        type  = "classic_conditions"
      })
    }
  }

  rule {
    name           = "High Memory Usage Alert"
    condition      = "B"
    for            = "2m"
    exec_err_state = "Alerting"
    no_data_state  = "NoData"

    labels = {
      severity = "critical"
    }

    data {
      ref_id          = "A"
      datasource_uid  = grafana_data_source.prometheus.uid
      query_type      = ""
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        expr         = "100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))"
        intervalMs   = 1000
        maxDataPoints = 43200
        refId        = "A"
      })
    }

    data {
      ref_id          = "B"
      datasource_uid  = "-100"
      query_type      = ""
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [
          {
            evaluator = { params = [80], type = "gt" }
            operator  = { type = "and" }
            query     = { params = ["A"] }
            reducer   = { params = [], type = "last" }
            type      = "query"
          }
        ]
        refId = "B"
        type  = "classic_conditions"
      })
    }
  }
}
