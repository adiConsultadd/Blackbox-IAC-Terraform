data "archive_file" "placeholder_layer" {
  type        = "zip"
  source_dir  = "${path.root}/placeholder-layer"
  output_path = "${path.root}/placeholder-layer.zip"
}

resource "aws_s3_bucket" "lambda_layers" {
  bucket = "${var.project_name}-${var.environment}-lambda-layers"
}

resource "aws_s3_object" "placeholder_layer" {
  bucket = aws_s3_bucket.lambda_layers.id
  key    = "placeholder-layer.zip"
  source = data.archive_file.placeholder_layer.output_path
  etag   = data.archive_file.placeholder_layer.output_md5
}
resource "aws_lambda_layer_version" "this" {
  for_each            = var.layers
  layer_name          = "${var.project_name}-${var.environment}-${each.key}"
  s3_bucket           = aws_s3_bucket.lambda_layers.id
  s3_key              = aws_s3_object.placeholder_layer.key
  
  compatible_runtimes = each.value.compatible_runtimes
  lifecycle {
    ignore_changes = [
      s3_key,
      s3_object_version,
      source_code_hash,
    ]
  }
}