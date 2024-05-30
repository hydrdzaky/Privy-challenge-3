terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.8.0"
    }
  }
}


provider "google" {
  region      = "asia-southeast2"
  project     = "proyekdicoding-416705"
  credentials = file("credentials.json")
  zone        = "asia-southeast2-a"

}