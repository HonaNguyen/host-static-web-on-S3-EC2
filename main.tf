provider "aws" {
    region = "us-east-1"
}

# S3 bucket
resource "aws_s3_bucket" "s3_bucket"{
    bucket = "hona-static-web-with-s3-ec2"
    object_lock_enabled = false
}

# Owner Control
resource "aws_s3_bucket_ownership_controls" "owner" {
    bucket = aws_s3_bucket.s3_bucket.id
    rule {
        object_ownership = "BucketOwnerEnforced"
    }
}


# Versioning
resource "aws_s3_bucket_versioning" "versioning_example" {
    bucket = aws_s3_bucket.s3_bucket.id
    versioning_configuration {
        status = "Disabled"
    }

}

# encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
    bucket = aws_s3_bucket.s3_bucket.id
    rule {
        bucket_key_enabled = true
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}


# Website
resource "aws_s3_bucket_website_configuration" "example" {
    bucket = aws_s3_bucket.s3_bucket.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "404.html"
    }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "name" {
    bucket = aws_s3_bucket.s3_bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

# Add policy
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
    bucket = aws_s3_bucket.s3_bucket.id
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*"
            ]
        }
    ]
}
POLICY
}


# Upload file to bucket
resource "aws_s3_object" "object1" {
    bucket = aws_s3_bucket.s3_bucket.bucket
    key = "index.html"
    source = "src/index.html"
    etag = filemd5("src/index.html")
}

# Upload file to bucket
resource "aws_s3_object" "object2" {
    bucket = aws_s3_bucket.s3_bucket.bucket
    key = "404.html"
    source = "src/404.html"
    etag = filemd5("src/404.html")
}


# EC2
resource "aws_instance" "name" {
    ami = "ami-0fa1ca9559f1892ec"
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl enable apache2
    systemctl start apache2

    aws s3 sync s3://${aws_s3_bucket.s3_bucket.bucket} /var/www/html
  EOF

    tags = {
        name = "hona-static-web"
    }
}

