terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket = "odo"
    region = "ru-central1"
    # key        = "prod/terraform.tfstate"
    key        = "terraform.tfstate"
    access_key = "some_access_key"
    secret_key = "some_secret_key"
    dynamodb_endpoint = "https://docapi.serverless.yandexcloud.net/dynamodb_endpoint"
    dynamodb_table = "some_dynamodb_table"

    skip_region_validation     = true
    skip_credentials_validation = true
  }
}
