# Consultadd » Blackbox Terraform IaC

> **Environments:** the repo ships with two Terraform workspaces
>   • `dev`
>   • `prod`

---

## 1. Quick‑start

```bash
# ➊ Clone and cd
git clone https://github.com/<org>/adiconsultadd-terraform-test.git
cd adiconsultadd-terraform-test

aws configure

# ➋ Initialise providers & modules
terraform init

# ➌ Select or create the workspace you need
terraform workspace list                # shows existing
terraform workspace new dev             # if first time
terraform workspace select dev          # or prod

# ➍ Validate & format
terraform fmt     -recursive
terraform validate

# ➎ Plan & apply
terraform plan   -var-file=dev.tfvars       # or prod.tfvars
terraform apply  -var-file=dev.tfvars
```

> **Tip:** add `-refresh=false` to `plan` for faster renders when nothing changed, or `-parallelism=N` to tune resource concurrency.

---

## 2. Typical commands

| Action                             | Command                                                                        |
| ---------------------------------- | ------------------------------------------------------------------------------ |
| See current state                  | `terraform state list`                                                         |
| Tail outputs for current workspace | `terraform output`                                                             |
| Destroy dev environment            | `terraform destroy -var-file=dev.tfvars`                                       |
| Add a new workspace (*e.g.* `qa`)  | `terraform workspace new qa` + create `qa.tfvars`                              |
| Switch provider versions           | Edit `versions.tf` → `terraform init -upgrade`                                 |
| Replace a single resource (target) | `terraform apply -target=module.feature_sourcing.aws_lambda_function.lambda_2` |

---

## 3. Outputs

After a successful `terraform apply`, you can retrieve these key values:

| Output Name               | Description                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------- |
| `sourcing_s3_bucket`      | Name of the S3 bucket used by the sourcing feature                                    |
| `cdn_domain_name`         | CloudFront distribution domain name                                                   |
| `eventbridge_rule_arn`    | ARN of the scheduled EventBridge rule                                                 |

```bash
# show all outputs in current workspace	
terraform output

# show one specific output            
terraform output cdn_domain_name
```

---