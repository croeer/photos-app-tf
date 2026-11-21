module "dynamodb_photos_label" {
  source  = "cloudposse/label/null"
  version = "0.25"
  context = module.this.context
  name    = "${var.app_name}-photos"
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
    projection_type = "ALL"

    key_schema {
      attribute_name = "GSI1PK"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "GSI1SK"
      key_type       = "RANGE"
    }
  }
}

module "dynamodb_likes_label" {
  source  = "cloudposse/label/null"
  version = "0.25"
  context = module.this.context
  name    = "${var.app_name}-likes"
}

resource "aws_dynamodb_table" "photo_likes_table" {
  count        = var.enable_likes ? 1 : 0
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

