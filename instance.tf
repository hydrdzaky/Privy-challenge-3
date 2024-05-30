resource "google_compute_instance" "default" {
  name         = "privy-challenge3"
  machine_type = "e2-small"
  zone         = "asia-southeast2-a"

  tags = ["ssh","http-server","nginx","https-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = "vpc-privy-challenge"
    subnetwork = "privy-subnet"

    access_config {
      // Ephemeral public IP
    }
  }
  

  metadata = {
    ssh-keys = ""
    startup-script = <<SCRIPT
        sudo apt update
        sudo apt upgrade -y
        sudo apt install apt-transport-https -y
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        apt-cache policy docker-ce
        sudo apt install docker-ce -y
        sudo usermod -aG docker $USER

        sudo docker run -d --name nginx -p 8080:80 nginx:latest
    SCRIPT
  }
}

