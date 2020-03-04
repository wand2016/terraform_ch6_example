resource "aws_s3_bucket" "private" {
  bucket = "terraform-practice-wand-20200305"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
