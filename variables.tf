variable "photos_upload_bucket_name" {
  description = "The name of the S3 bucket with the uploaded photos."
  type        = string
}

variable "photos_store_bucket_name" {
  description = "The name of the S3 bucket with the resized photos."
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "photos_table_name" {
  description = "The name of the DynamoDB table with the photos."
  type        = string
  default     = "photos-table"
}
