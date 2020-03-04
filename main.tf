resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "private" {
  bucket = "terraform-practice-wand-20200305"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "private" {
  bucket = aws_s3_bucket.private.id
  policy = data.aws_iam_policy_document.private.json
}

data "aws_iam_policy_document" "private" {
  # SSE-KMSでない暗号化を禁止
  statement {
    sid = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.private.id}/*"]
    condition {
      test = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "aws:kms"
      ]
    }
  }
  # 暗号化されていないアップロードを禁止
  statement {
    sid = "DenyUnEncryptedObjectUploads"
    effect = "Deny"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.private.id}/*"]
    condition {
      test = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "true"
      ]
    }
  }
}


resource "aws_s3_bucket" "public" {
  bucket = "terraform-practice-wand-20200305-public"
  acl = "public-read"

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "terraform-practice-wand-20200305-log"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

output "mykey_arn" {
  value = aws_kms_key.mykey.arn
}
