provider "google" {
 credentials = file("e0905a2dcabe.json")
 project     = "evbox-infrastructure"
 region      = "europe-west1"
 zone        = "europe-west1-d"
}

provider "kubernetes" {
  load_config_file       = false
  host                   = module.everon-k8s-cluster.endpoint
  username = var.username
  password = var.password
  client_certificate     = base64decode(module.everon-k8s-cluster.cluster_client_certificate)
  client_key             = base64decode(module.everon-k8s-cluster.cluster_client_key)
  cluster_ca_certificate = base64decode(module.everon-k8s-cluster.cluster_ca_certificate)
}


module "everon-k8s-cluster" {
  source                     = "./modules"
}

resource "kubernetes_deployment" "nginxdemo" {
  metadata {
    name      = "nginxdemo"
    namespace = "nginx-deploy"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        run = "nginxdemo"
      }
    }
    template {
      metadata {
        labels = {
          run = "nginxdemo"
        }
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

resource "kubernetes_ingress" "my_ingress_1" {
  metadata {
    name      = "my-ingress-1"
    namespace = "nginx-deploy"
    annotations = {
      "acme.cert-manager.io/http01-edit-in-place" = "true"
      "cert-manager.io/issuer" = "letsencrypt-prod"
      "kubernetes.io/ingress.allow-http" = "true"
      "kubernetes.io/ingress.global-static-ip-name" = "static-ip-1"
    }
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