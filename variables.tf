variable "photos_upload_bucket_name" {
  description = "The name of the S3 bucket with the uploaded photos."
  type        = string
}

variable "photos_store_bucket_name" {
  description = "The name of the S3 bucket with the resized photos."
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central1"
}
