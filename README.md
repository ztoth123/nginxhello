# Everon's DevOps assignment solution with Terraform
## The requirements
1. Use Terraform to create & deploy all required resources
2. Use Google Cloud Storage as a backend and devops-assignment bucket to share the Terraform statefile
3. Use `nginxdemos/hello` Docker image as the target microservice
4. Run the microservice in a replicated but cost-efficient configuration
5. Provide usage instructions in README.md

## Added awesomeness
6. Expose the service through a DNS record
7. Setup the Let's Encrypt certificate and enforce a secured connection

## Questions!
1. What is your favourite feature that GCP or it 's competitor has recently brought to market, and how are you intending to use it ?
2. What future or current technology do you look forward to the most or want to use and why?

## Solution
### Prerequisites
- preconfigured GCP project and storage bucket with provided credentials 
- installed `terraform` tool
- installed `kubectl` tool
- installed `gcloud` tool
- registered DNS (sub)domain
 
### Configured GCP services
1. GCP node-pool with 2 node instances
2. GKE container cluster on the node-pool
3. GCP Global static IP address
4. GKE `ingress-gce` k8s ingress controller (+ automatically added GCP services: ssl, tp, um, fw, fws, tps)

### Terraform module structure and files
```
├── main.tf
├── variables.tf
├── ...
├── modules/
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
```

### The provisioning process by the Terraform files
##### Download the `google` and the `kubernetes` terraform modules
1. Run the `terraform init` command to download the 2 provider modules defined in the root `main.tf` file

##### Create a k8s cluster
1. The `google` provider module uses the `evbox-infrastructure` project with the `e0905a2dcabe.json` file
   content to authenticate itself into GCP
2. The `google` provider module provisions the the `modules/main.tf`
   file defined `primary_preemptible_nodes` node-pool resource on GCE 
3. The `google` provider module provisions the the `modules/main.tf`
   file defined `primary` cluster named `ztoth-k8s-cluster`
4. The `modules/output.tf` file defined output values are populated from the `google_container_cluster.primary` resource.
   These output values are used as input values by the parent defined `main.tf` `kubernetes` provider for authentication.

##### Additional settings on GCP
1. Set the authentication for the `gcloud` tool by resource `"null_resource" "gcloud_commands"` `local-exec` commands:
- `gcloud config set project evbox-infrastructure`
- `gcloud config set compute/zone europe-west1-d`
- `gcloud auth activate-service-account devops-assignment@evbox-infrastructure.iam.gserviceaccount.com --key-file=e0905a2dcabe.json --project=evbox-infrastructure`
2. Set the local `kubectl` parameters into the `~/.kube/config` file for later `local-exec` `kubectl` commands:
- `gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone=europe-west1-d`
3. Created a global GCP static IP entry for the ingress VIP:
- `gcloud compute addresses create static-ip-1 --global`

Note: Explicit dependency on `google_container_cluster.primary` resource is defined!

##### Cert-manager installation
- `kubectl create namespace cert-manager`
- `kubectl create namespace nginx-deploy`
- `kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)`
- `kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml`
- `kubectl apply -f cert-manager-issuers.yaml`

Note: Explicit dependency on `null_resource.gcloud_commands` resource is defined!
