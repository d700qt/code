variable "vm_name" {
    type = "string"
}

variable "num_cpus" {
    type = "string"
}

variable "instances" {
    type = "string"
}
variable "ip_addresses" {
    type = "map"
    //default = ["10.180.104.150"]
}

variable "vc_folder" {
    type = "string"
}

/*
variable "vc_user" {}
variable "vc_password" {}
variable "vc_server" {}
*/