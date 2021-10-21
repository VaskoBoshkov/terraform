terraform {
  backend "remote" {
    organization = "vasko-terraform"

    workspaces {
      name = "vasko-dev"
    }
  }
}