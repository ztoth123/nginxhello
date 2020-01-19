provider "google" {
 credentials = file("e0905a2dcabe.json")
 project     = "evbox-infrastructure"
 region      = "europe-west1"
 zone        = "europe-west1-d"
}

provider "kubernetes" {
  load_config_file       = false
  host                   = module.everon-k8s-cluster.endpoint
  username = "admin"
  password = "laehub3Otahshec7"
  client_certificate     = base64decode(module.everon-k8s-cluster.cluster_client_certificate)
  client_key             = base64decode(module.everon-k8s-cluster.cluster_client_key)
  cluster_ca_certificate = base64decode(module.everon-k8s-cluster.cluster_ca_certificate)
}

resource "kubernetes_namespace" "nginx-deploy" {
  metadata {
    name = "nginx-deploy"

    labels = {
      label = "nginx"
    }
  }
}

module "everon-k8s-cluster" {
  source                     = "./modules"
}