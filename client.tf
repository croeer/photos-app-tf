
module "client_bucketlabel" {
  source     = "cloudposse/label/null"
  version    = "0.25"
  context    = module.this.context
  name       = "${var.app_name}-client"
  attributes = ["s3", var.aws_account_id]
}

module "client_homepage_spa" {
  source = "git::https://github.com/croeer/aws-homepage-s3-cf-tf.git?ref=v1.0.1"

  bucket_name         = module.client_bucketlabel.id
  custom_domain_names = var.custom_domain_names
  acm_certificate_arn = var.acm_certificate_arn

}
