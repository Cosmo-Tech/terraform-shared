## Since 2.0.0 ("count" has been added to each modules)
moved {
  from = module.chart_traefik
  to   = module.chart_traefik[0]
}

moved {
  from = module.chart_cert_manager
  to   = module.chart_cert_manager[0]
}

moved {
  from = module.chart_cnpg
  to   = module.chart_cnpg[0]
}

moved {
  from = module.chart_harbor
  to   = module.chart_harbor[0]
}

moved {
  from = module.chart_keycloak
  to   = module.chart_keycloak[0]
}

moved {
  from = module.chart_prometheus_stack
  to   = module.chart_prometheus_stack[0]
}

moved {
  from = module.chart_superset
  to   = module.chart_superset[0]
}

moved {
  from = module.workload_scheduler
  to   = module.workload_scheduler[0]
}
