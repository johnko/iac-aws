output "bucket" {
  value = aws_s3_bucket.bucket
}

output "bucket_versioning" {
  value = aws_s3_bucket_versioning.bucket
}
