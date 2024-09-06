provider "aws" {
  region = "eu-west-1"
}

module "private_vpc" {
  source              = "../../"
  name                = "test"
  cidr_block          = "192.168.0.0/24"
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnet_bits = 26

  tags = {
    environment = "test"
  }
}

module "private_vpc_with_lambda" {
  source              = "../../"
  name                = "test"
  cidr_block          = "192.168.1.0/24"
  availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnet_bits = 28
  lambda_subnet_bits  = 28

  tags = {
    environment = "test"
  }
}
