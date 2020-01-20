resource "kubernetes_namespace" "nginx_deploy" {
  metadata {
    name = "nginx-deploy"

    labels = {
      label = "nginxdemo"
    }
  }
}

