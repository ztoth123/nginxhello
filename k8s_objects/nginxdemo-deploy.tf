resource "kubernetes_deployment" "nginxdemo" {
  metadata {
    name      = "nginxdemo"
    namespace = "nginx-deploy"
  }
  spec {
    replicas = 2
    selector {
      match_labels = { run = "nginxdemo" }
    }
    template {
      metadata {
        labels = { run = "nginxdemo" }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginxdemos/hello"
          liveness_probe {
            http_get {
              path = "/health/live"
              port = "80"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/health/ready"
              port = "80"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}
