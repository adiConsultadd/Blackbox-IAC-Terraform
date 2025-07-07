resource "null_resource" "pip_install" {
  for_each = var.layers
  triggers = {
    requirements_hash = filemd5("${each.value.source_path}/requirements.txt")
  }
  provisioner "local-exec" {
    command = "pip install -r ${each.value.source_path}/requirements.txt -t ${path.module}/build/${each.key}/python"
  }
}

resource "aws_s3_bucket" "lambda_layers" {
  bucket = "${var.project_name}-${var.environment}-lambda-layers"
}

data "archive_file" "layer_zips" {
  for_each    = var.layers
  type        = "zip"
  source_dir  = "${path.module}/build/${each.key}"
  output_path = "${path.module}/build/${each.key}.zip"
  depends_on = [null_resource.pip_install]
}

resource "aws_s3_object" "layer_objects" {
  for_each = var.layers
  bucket   = aws_s3_bucket.lambda_layers.id
  key      = "${each.key}.zip"
  source   = data.archive_file.layer_zips[each.key].output_path
  etag     = filemd5(data.archive_file.layer_zips[each.key].output_path)
}

resource "aws_lambda_layer_version" "this" {
  for_each            = var.layers
  layer_name          = "${var.project_name}-${var.environment}-${each.key}"
  s3_bucket           = aws_s3_bucket.lambda_layers.id
  s3_key              = aws_s3_object.layer_objects[each.key].key
  source_code_hash    = data.archive_file.layer_zips[each.key].output_base64sha256
  compatible_runtimes = each.value.compatible_runtimes
}
