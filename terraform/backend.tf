# Remote state in S3 with DynamoDB locking.
#
# Bootstrap (one-time, before first terraform init):
#   aws s3 mb s3://judge-engine-tfstate-<ACCOUNT_ID> --region us-east-1
#   aws s3api put-bucket-versioning \
#     --bucket judge-engine-tfstate-<ACCOUNT_ID> \
#     --versioning-configuration Status=Enabled
#   aws dynamodb create-table \
#     --table-name judge-engine-tflock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region us-east-1

terraform {
  backend "s3" {
    bucket         = "judge-engine-tfstate-722851019025"
    key            = "judge-engine/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "judge-engine-tflock"
    encrypt        = true
  }
}
