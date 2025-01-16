module "client_homepage_spa" {
  source = "git::https://github.com/croeer/aws-homepage-s3-cf-tf.git"

  bucket_name         = var.client_bucket_name
  custom_domain_names = var.custom_domain_names
  acm_certificate_arn = var.acm_certificate_arn

}
