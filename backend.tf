terraform {

  backend "s3"{
      bucket = "talent-academy-account-tfstates-t3"
      key = "Challenge/terraform.tfstate"
      #dynamodb_table = "terraform-lock"
  }
}