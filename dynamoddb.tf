resource "aws_dynamodb_table" "photo_table" {
  name         = var.photos_table_name
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

resource "aws_dynamodb_table" "photo_likes_table" {
  name         = var.photo_likes_table_name
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

