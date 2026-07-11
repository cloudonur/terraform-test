# Demo Terraform config used to test the onurglr/iac-sentinel action.
# It intentionally declares risky infrastructure so the reviewer has something to
# flag. It is NEVER applied: the AWS provider below uses mock credentials and skip
# flags, so `terraform plan` runs fully offline — no cloud account required.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Mock provider: skip every credential/metadata lookup so plan needs no real AWS.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# (1) Deterministic rule — open_ingress: SSH exposed to the entire internet.
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "demo web security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# (2) Deterministic rule — expensive_compute: a very costly GPU instance type.
resource "aws_instance" "trainer" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "p4d.24xlarge"

  tags = {
    Name = "ml-trainer"
  }
}

# (3) Deterministic rule — unencrypted_storage: database with encryption disabled.
resource "aws_db_instance" "main" {
  identifier                  = "demo-db"
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  username                    = "admin"
  manage_master_user_password = true
  skip_final_snapshot         = true
  storage_encrypted           = false
}

# (4) LLM (contextual ceiling) — a bucket left publicly accessible.
resource "aws_s3_bucket" "exports" {
  bucket = "customer-exports-prod-demo"
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = false
}
