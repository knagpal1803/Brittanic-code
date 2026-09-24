variable "credentials" {
  description = "credetails for docker container" #These secretes should be get from AWS secret manager using data blocks
  default = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=strongpassword123"
  ]
}

variable "AUTH_VAR"{
  decscription = "Aunthenitcation details for provider config"
  default = "admin:strongpassword123" # I will get these secrets from AWS secret manager using data block in prod env
}
