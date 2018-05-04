/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/

resource "azurerm_resource_group" "test" {
  name     = "acctestrg"
  location = "West US 2"
}

/*
resource "aws_instance" "my_instance" {
  count = "2"
  ami = "ami-25615740"
  instance_type = "t2.micro"

  tags {
    Name = "HelloWorld-${count.index}"
  }
}*/

module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "1.3.0"

  name           = "my-ec2"
  instance_count = 1
  
  ami                    = "ami-8e1627eb" # windows 2016
  instance_type          = "t2.micro"
  associate_public_ip_address = "true"
  monitoring             = false
  vpc_security_group_ids = ["sg-3d792c56"]
  subnet_id              = "subnet-dd4a7490"

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}