resource "google_container_cluster" "primary" {
  name     = "ztoth-k8s-cluster"
  location = "europe-west1-d"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = var.username
    password = var.password
    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "ztoth-node-pool"
  location   = "europe-west1-d"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "null_resource" "gcloud_commands" {
  provisioner "local-exec" {
    command = "gcloud config set project evbox-infrastructure"
  }
  provisioner "local-exec" {
    command = "gcloud config set compute/zone europe-west1-d"
  }
  provisioner "local-exec" {
    command = "gcloud auth activate-service-account devops-assignment@evbox-infrastructure.iam.gserviceaccount.com --key-file=e0905a2dcabe.json --project=evbox-infrastructure"
    working_dir = "/home/z/Documents/Everon"
  }
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone=europe-west1-d"
  }
  provisioner "local-exec" {
    command = "gcloud compute addresses create static-ip-1 --global"
  }

  depends_on = [google_container_cluster.primary]
}

resource "null_resource" "install_cert_manager" {
  provisioner "local-exec" {
    command = "kubectl create namespace cert-manager"
  }
  provisioner "local-exec" {
    command = "kubectl create namespace nginx-deploy"
  }
  provisioner "local-exec" {
    command = "kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)"
  }
  provisioner "local-exec" {
    command = "kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f cert-manager-issuers.yaml"
    working_dir = "/home/z/Documents/Everon/k8s_objects/cert-manager"
  }

  depends_on = [null_resource.gcloud_commands]
}