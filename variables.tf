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

variable "client_bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central1"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the API Gateway custom domain (us-east-1)."
  type        = string
  default     = ""
}

variable "custom_domain_names" {
  description = "The custom domain name for the API Gateway."
  type        = list(string)
  default     = []
}

variable "max_photos_per_request" {
  description = "The maximum number of photos to upload in a single request."
  type        = number
  default     = 15
}

variable "enable_photochallenge" {
  description = "Enable the photo challenge feature."
  type        = bool
  default     = true
}

variable "enable_photoupload" {
  description = "Enable the photo upload feature."
  type        = bool
  default     = true
}
