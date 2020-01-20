resource "kubernetes_service" "nginxdemo_service" {
  metadata {
    name      = "nginxdemo-service"
    namespace = "nginx-deploy"

    labels = {
      run = "nginxdemo"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 6000
      target_port = "80"
    }

    selector = {
      run = "nginxdemo"
    }

    type             = "NodePort"
    session_affinity = "None"
  }
}

