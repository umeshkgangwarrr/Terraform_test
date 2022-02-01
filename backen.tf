terraform {
  backend "s3" {
    bucket = "terraformstatfile"
    key    = "workspace/terraform.tfstate"
    region = "ap-south-1"
    #dynamodb_table = "terraformdb" # create dynamodb table to store lockid of statefile where put primary id as lockid
    # also create the db in same region where we have S3bucket.
  }
}