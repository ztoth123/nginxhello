resource "kubernetes_ingress" "my_ingress_1" {
  metadata {
    name        = "my-ingress-1"
    namespace   = "nginx-deploy"
    annotations = { "acme.cert-manager.io/http01-edit-in-place" = "true", "cert-manager.io/issuer" = "letsencrypt-prod", "kubernetes.io/ingress.allow-http" = "true", "kubernetes.io/ingress.global-static-ip-name" = "static-ip-1" }
  }
  spec {
    tls {
      hosts       = ["nginx.everon.dns-cloud.net"]
      secret_name = "tls-secret-1"
    }
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "nginxdemo-service"
            service_port = "6000"
          }
        }
      }
    }
  }
}
