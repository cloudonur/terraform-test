# terraform-test — iac-sentinel consumer demo

A minimal **Terraform** repository that consumes the published
[`onurglr/iac-sentinel`](https://github.com/onurglr/iac-sentinel) GitHub Action.

On every pull request, CI generates a `terraform plan` and iac-sentinel reviews it,
posting its security/cost findings as a single PR comment — proving the action works
from a separate repository.

## How it works

- `main.tf` — intentionally risky infra so the reviewer has something to flag:
  - SSH open to `0.0.0.0/0` (a security group)
  - a `p4d.24xlarge` GPU instance (cost blow-up)
  - a database with encryption at rest disabled
  - a publicly accessible S3 bucket
- `.github/workflows/review.yml` — on each PR: `terraform init/plan/show -json`,
  then `uses: onurglr/iac-sentinel@v1` with the generated `plan.json`.

**No cloud account needed.** The AWS provider is configured with mock credentials
and `skip_*` flags, so `terraform plan` runs fully offline. The config is never
applied — it exists only to produce a realistic plan for the reviewer.

> Requires the `v1` tag published on `onurglr/iac-sentinel`.
