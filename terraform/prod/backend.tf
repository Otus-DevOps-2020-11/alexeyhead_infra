terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket = "odo"
    region = "ru-central1"
    # key        = "prod/terraform.tfstate"
    key        = "terraform.tfstate"
    access_key = "IiiorWMMHMicvxEm2g2R"
    secret_key = "UnSvHaUDcIyyypNeZl-2rJl9G-OQLmy5zIvr5F8l"
    #access_key = "ToMA0qxN5koRN2RIU15d"
    #secret_key = "1_P3q1bTXBuD7HEgCEjV_1pH9tZLxG-qesqMAiIw"
    dynamodb_endpoint = "https://docapi.serverless.yandexcloud.net/ru-central1/b1gr7ijt35laouif2ch5/etn03jtomlsin4ke6mo4"
    dynamodb_table = "terraform_lock_state"

    skip_region_validation     = true
    skip_credentials_validation = true
  }
}
