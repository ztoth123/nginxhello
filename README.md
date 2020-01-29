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
I would like to use all of the 3 main cloud providers' services, no faovourite feature I have.

2. What future or current technology do you look forward to the most or want to use and why?
https://www.consul.io/ as it is an interesting and platform independent networking solution for inter-cluster or inter-cloud pod communication.
And I was originally a network engineer:)

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
##### terraform commands to use
1. Run the `terraform init` command to download the 2 provider modules defined in the root `main.tf` file
2. Use the `terraform plan -out=output1` command to create the plan file for the infrastructure
3. Apply the `terraform apply "output1"` command to provision IAAC and generate the `terraform.state` file

Note: the `terraform apply "output1"` command executing the following configurations steps on the GCP

##### step1: Creating a k8s cluster
1. The `google` provider module uses the `evbox-infrastructure` project with the `e0905a2dcabe.json` file
   content to authenticate itself into GCP
2. The `google` provider module provisions the the `modules/main.tf`
   file defined `primary_preemptible_nodes` node-pool resource on GCE 
3. The `google` provider module provisions the the `modules/main.tf`
   file defined `primary` cluster named `ztoth-k8s-cluster`
4. The `modules/output.tf` file defined output values are populated from the `google_container_cluster.primary` resource.
   These output values are used as input values by the parent defined `main.tf` `kubernetes` provider for authentication.

##### step2: Additional settings on GCP
1. Setting the authentication for the `gcloud` tool by resource `"null_resource" "gcloud_commands"` `local-exec` commands:
- `gcloud config set project evbox-infrastructure`
- `gcloud config set compute/zone europe-west1-d`
- `gcloud auth activate-service-account devops-assignment@evbox-infrastructure.iam.gserviceaccount.com --key-file=e0905a2dcabe.json --project=evbox-infrastructure`
2. Setting the local `kubectl` parameters into the `~/.kube/config` file for later `local-exec` `kubectl` commands:
- `gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone=europe-west1-d`
3. Creating a global GCP static IP entry for the ingress VIP:
- `gcloud compute addresses create static-ip-1 --global`

Note: Explicit dependency on `google_container_cluster.primary` resource is defined!

##### step3: Cert-manager installation
- `kubectl create namespace cert-manager`
- `kubectl create namespace nginx-deploy`
- `kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)`
- `kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml`
- `kubectl apply -f cert-manager-issuers.yaml`

Notes: 
- Explicit dependency on `null_resource.gcloud_commands` resource is defined!
- cert-manager is installed in the `cert-manager` namespace
- `nginx-deploy` namespace is configured here as the cert-manager `Issuer` is namespace-aware

##### step4: K8s resource installation in the `nginx-deploy` namespace
1. the `kubernetes` provider using the child module provided output values for authentication
2. the following k8s objects are provisioned by the root `main.tf` kubernetes resources:
- Deployment with 2 replicas with using the `nginxdemos/hello` Docker image in each
- Nodeport Service for cluster inside load-balancing from other pods
- Ingress object referring to the Nodeport service as backend and using the predefined static IP as frontend VIP
  This ingress is a L7 load-balancer configuration for TLS and using the cert-manager to ask for Letsencrypt certificate.
  The initial and the Letsencrypt ACME issued certificates are stored in the `tls-secret-1` secret.

Notes: 
- Implicit dependency is defined by the provider authentication child module output references
- An A record is created manually under the also manually pre-registered `everon.dns-cloud.net` subdomain
  A record: `nginx` --> `34.107.232.107`
  
### The DNS and data flow from an Internet client to the `nginxdemos/hello` microservice
```
  ├ ─ ─> DNS server: nginx.everon.dns-cloud.net > 34.107.232.107 
  |
  |                       |───────────|   |──────────|────> nginx pod
client ├──> VIP:          |  ingress  |──>| service  |
           34.107.232.107 |───────────|   |──────────|────> nginx pod


```

The microservice is available here:
https://nginx.everon.dns-cloud.net
