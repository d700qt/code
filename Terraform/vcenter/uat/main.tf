/*
data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "adeweetmans3"
    key    = "terraform/uat/terraform.tfstate"
    region = "eu-west-2"
    encrypt = true
    access_key = "blah"
    secret_key = "password"
  }
}
*/

# Configure the vsphere provider
provider "vsphere" {
  user           = "${var.vc_user}"
  password       = "${var.vc_password}"
  vsphere_server = "${var.vc_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "SandPit-DC"
}

resource "null_resource" "dosomestuff" {
  provisioner "local-exec" {
    command     = "get-service | out-file -filepath 'null_resource.txt'"
    interpreter = ["PowerShell", "-Command"]
  }
}

/*
module "files" {
  source  = "../modules/global/terraform-shell-resource"
  version = "0.0.1"
  command = "dir"
}

output "my_files" {
  value = "${module.files.stdout}"
}
*/

resource "vsphere_folder" "tffolder" {
  path          = "/vRA Development/Stream1002/terraform-test-folder"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"

  provisioner "local-exec" {
    command = <<EOT
      get-service | out-file -filepath 'service.txt';
      get-module | add-content -path 'service.txt';
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
}

/*variable "max_instances" {
  type = "string"
  default = "5"
}*/

/*variable "machines" {
  type = "map"
  default = {
    serverrole1-name = "serverrole1"
    serverrole1-max_instances = 3
    serverrole2-name = "serverrole2"
    serverrole2-max_instances = 3
  }
}
*/

module "serverrole1" {
  source    = "../modules/windows_server_2016"
  vm_name   = "role1"
  vc_folder = "${vsphere_folder.tffolder.path}"
  instances = 1
  num_cpus  = 2

  ip_addresses = {
    "0" = "10.180.104.150"
    "1" = "10.180.104.151"
  }
}

output ips {
  value = ["${module.serverrole1.ip}"]
}

module "serverrole2" {
  source    = "../modules/windows_server_2016"
  vm_name   = "role2"
  vc_folder = "${vsphere_folder.tffolder.path}"
  instances = 1
  num_cpus  = 1

  ip_addresses = {
    "0" = "10.180.104.160"
    "1" = "10.180.104.161"
  }
}
