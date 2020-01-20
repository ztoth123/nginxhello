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

### Terraform provisioned resource list
