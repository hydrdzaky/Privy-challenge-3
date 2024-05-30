resource "google_container_cluster" "primary" {
  name                     = "privy-cluster"
  location                 = "asia-southeast2-a"
  network                  = "vpc-privy-challenge"
  subnetwork               = "privy-subnet"
  remove_default_node_pool = true                ## create the smallest possible default node pool and immediately delete it.
  # networking_mode          = "VPC_NATIVE" 
  initial_node_count       = 1
  
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes   = true 
    master_ipv4_cidr_block = "10.13.0.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.11.0.0/21"
    services_ipv4_cidr_block = "10.12.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.7/32"
      display_name = "authnet"
    }

  }
}

# Create managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = "asia-southeast2-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1
  max_pods_per_node = 8

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    machine_type = "n1-standard-1"
    preemptible  = true
    #service_account = google_service_account.mysa.email

    metadata = {
      disable-legacy-endpoints = "true"
    }
    tags = ["ssh","nginx"]
  }
}



## Create jump host . We will allow this jump host to access GKE cluster. the ip of this jump host is already authorized to allowin the GKE cluster

resource "google_compute_address" "my_internal_ip_addr" {
  project      = "proyekdicoding-416705"
  address_type = "INTERNAL"
  region       = "asia-southeast2"
  subnetwork   = "privy-subnet"
  name         = "my-ip"
  address      = "10.0.0.7"
  description  = "An internal IP address for my jump host"
}




## Create IAP SSH permissions for your test instance

resource "google_project_iam_member" "project" {
  project = "proyekdicoding-416705"
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:privy-challenge@proyekdicoding-416705.iam.gserviceaccount.com"
}

# create cloud router for nat gateway
resource "google_compute_router" "router" {
  project = "proyekdicoding-416705"
  name    = "privy-nat-router"
  network = "vpc-privy-challenge"
  region  = "asia-southeast2"
}

## Create Nat Gateway with module

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.4.0"
  project_id = "proyekdicoding-416705"
  region     = "asia-southeast2"
  router     = google_compute_router.router.name
  name       = "privy-nat-config"

}


############Output############################################
output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}