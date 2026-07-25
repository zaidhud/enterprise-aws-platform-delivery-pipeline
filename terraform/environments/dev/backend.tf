terraform {
  backend "s3" {
    bucket       = "eapdp-874456855495-eu-west-2-tfstate"
    key          = "environments/dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
