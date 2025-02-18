module "dynamodb_photos_label" {
  source  = "cloudposse/label/null"
  version = "0.25"
  context = module.this.context
  name    = var.photos_table_name
}

resource "aws_dynamodb_table" "photo_table" {
  name         = module.dynamodb_photos_label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }
}

module "dynamodb_likes_label" {
  source  = "cloudposse/label/null"
  version = "0.25"
  context = module.this.context
  name    = var.photo_likes_table_name
}

resource "aws_dynamodb_table" "photo_likes_table" {
  name         = module.dynamodb_likes_label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"
  range_key    = "ImageId"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "ImageId"
    type = "S"
  }

}

