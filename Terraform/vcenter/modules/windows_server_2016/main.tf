/*
provider "vsphere" {
  user           = "${var.vc_user}"
  password       = "${var.vc_password}"
  vsphere_server = "${var.vc_server}"
  
  # if you have a self-signed cert
  allow_unverified_ssl = true
}
*/

data "vsphere_datacenter" "dc" {
  name = "SandPit-DC"
}

data "vsphere_datastore" "datastore" {
  name          = "v01-0011a-L011"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "resourcepool" {
  name          = "SandPit-Cluster/Resources"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "vxw-dvs-301-virtualwire-694-sid-5023-LS_Stream1002_VXLAN"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "_Template_Win2k16"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.vm_name}-${count.index}"
  count            = "${var.instances}"
  resource_pool_id = "${data.vsphere_resource_pool.resourcepool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${var.vc_folder}"

  num_cpus = "${var.num_cpus}"
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "true"

    customize {
      windows_options {
        computer_name         = "${var.vm_name}-${count.index}"
        join_domain           = "<removed>"
        domain_admin_user     = "<removed>@<removed>"
        domain_admin_password = "<removed>"
      }

      network_interface {
        ipv4_address    = "${lookup(var.ip_addresses, count.index)}"
        ipv4_netmask    = 22
        dns_server_list = ["10.180.100.15"]                          #tstmgmt DC
      }

      timeout = "0"

      ipv4_gateway = "10.180.104.1"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      $password = "<removed>" | ConvertTo-SecureString -asPlainText -Force;
      $username = "<removed>";
      $password | out-file -filepath "${var.vm_name}.txt"
      $username | add-content -path "${var.vm_name}.txt"
      $cred = New-Object System.Management.Automation.PSCredential($username,$password);  
      while ($true) {
        try {
          $pssession = New-PSSession -ComputerName ${lookup(var.ip_addresses, count.index)} -Credential $cred -ErrorAction Stop
        } catch {
          write-warning -message "Oops, not ready"
        }
        if ($pssession -eq $null) {
          Start-Sleep -Seconds 20
        } else {
            break;
            Write-Host "pssession established";
        }
      }
      icm -Session $pssession -ScriptBlock {get-service | select -property name | add-content -path "c:\temp\services.txt"}     EOT

    interpreter = ["PowerShell", "-Command"]
  }

  /*provisioner "remote-exec" {
    inline = ["get-service | outfile -filepath 'c:\\temp\\services.txt'"]

    connection {
      type     = "winrm"
      user     = "<removed>"
      password = "<removed>"
      timeout = "10m"
    }
  }*/
}

output "ip" {
  value = ["${vsphere_virtual_machine.vm.*.default_ip_address}"]
}
