variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "photosapp"
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

variable "photo_likes_table_name" {
  description = "The name of the DynamoDB table with the photo likes."
  type        = string
  default     = "photo-likes-table"
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
  default     = 50
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

variable "idp_config" {
  description = "The configuration for the identity provider."
  type = object({
    realm     = string
    idp_url   = string
    client_id = string
  })
  default = null
}

variable "enable_likes" {
  description = "Enable the image like feature"
  type        = bool
  default     = true
}

variable "theme_config" {
  description = "Theming configuration like header, logo etc."
  type = object({
    header      = string
    subHeader   = string
    description = string
    title       = string
  })
  default = {
    header      = "Photo App"
    subHeader   = "Upload and share your photos"
    description = "This is a simple photo app to upload and share photos"
    title       = "Photo App"
  }
}
