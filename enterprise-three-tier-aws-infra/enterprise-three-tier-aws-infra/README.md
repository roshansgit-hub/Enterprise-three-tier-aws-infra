# Enterprise Three-Tier AWS Infrastructure

Production-style, three-tier web architecture on AWS, fully defined as code:
**Terraform** for infrastructure, **Docker** for the application layer, **GitHub
Actions** for CI/CD, and **CloudWatch/Grafana** for monitoring — with security
baked in at every tier rather than bolted on afterward.

## Architecture

```
                              Internet
                                 |
                        [ Internet Gateway ]
                                 |
                    ┌────────────────────────┐
                    │   Public Subnets (x3)  │   <- Web Tier
                    │  Application Load      │
                    │  Balancer (HTTPS)      │
                    └───────────┬────────────┘
                                |
                    ┌───────────▼────────────┐
                    │  Private App Subnets   │   <- App Tier
                    │  EC2 Auto Scaling Group│
                    │  (Dockerized app, ECR) │
                    └───────────┬────────────┘
                                |
                    ┌───────────▼────────────┐
                    │  Private DB Subnets    │   <- Data Tier
                    │  RDS PostgreSQL        │
                    │  (Multi-AZ, encrypted) │
                    └────────────────────────┘

Cross-cutting: VPC Flow Logs, CloudWatch alarms/dashboards,
Secrets Manager, KMS encryption, IAM least-privilege roles.
```

Each tier sits in its own subnet group and can only be reached from the tier
directly above it — the ALB security group accepts traffic from the internet,
the app security group only accepts traffic from the ALB, and the database
security group only accepts traffic from the app tier.

## Repository layout

```
terraform/
  modules/
    vpc/            # 3-tier VPC, subnets, NAT, route tables, flow logs
    security/       # Security groups (ALB -> App -> DB chain)
    alb/             # Application Load Balancer + HTTPS listener
    ec2-asg/         # Launch template + Auto Scaling Group for the app tier
    rds/             # Multi-AZ PostgreSQL, encrypted, Secrets Manager
  environments/
    dev/            # Smaller, cheaper footprint (single NAT, single-AZ RDS)
    prod/           # HA footprint (per-AZ NAT, Multi-AZ RDS, deletion protection)

docker/
  app/Dockerfile     # Multi-stage, non-root, health-checked app image
  web/nginx.conf     # Local reverse proxy config
  docker-compose.yml # Full local stack: web -> app -> db

monitoring/
  cloudwatch/        # Dashboard + alarms module (5xx, CPU, DB storage, etc.)
  grafana/            # Equivalent Grafana dashboard JSON

.github/workflows/
  ci.yml              # terraform fmt/validate, tflint, checkov, trivy, tests
  cd.yml              # Build & push to ECR, terraform plan, gated apply

scripts/deploy.sh     # Local convenience wrapper around terraform plan/apply
```

## Key design decisions

- **Least-privilege networking** — nothing but the ALB is internet-facing;
  app and DB subnets have no route to the internet except outbound via NAT.
- **IAM roles over long-lived keys** — EC2 instances use an instance profile
  (SSM + ECR read-only); CI/CD authenticates to AWS via GitHub OIDC, no
  static AWS access keys stored anywhere.
- **Encryption everywhere** — EBS volumes, RDS storage (customer-managed KMS
  key with rotation), and DB credentials in Secrets Manager rather than
  Terraform variables.
- **IMDSv2 enforced** on all EC2 instances; VPC Flow Logs shipped to
  CloudWatch for network audit trails.
- **Environment separation** — `dev` and `prod` are separate Terraform root
  modules with separate state files and independently tunable footprints
  (dev: single NAT gateway, single-AZ RDS, no deletion protection; prod: HA
  NAT per AZ, Multi-AZ RDS, deletion protection on).
- **CI/CD gating** — every PR runs `terraform fmt`/`validate`, `tflint`, a
  Checkov IaC security scan, and a Trivy image vulnerability scan before
  merge. Deploys build once, then plan and (after environment-protected
  approval) apply the same artifact to `dev` or `prod`.

## Prerequisites

- Terraform >= 1.7
- An AWS account with an OIDC identity provider trusting your GitHub repo
  (for CD), or local AWS credentials (for manual `scripts/deploy.sh` runs)
- An S3 bucket + DynamoDB table for Terraform remote state locking
  (referenced in `terraform/environments/*/main.tf` — replace the
  placeholder bucket name before first use)
- An ACM certificate for the ALB's HTTPS listener

## Getting started

```bash
# Local app + db stack, no AWS required
cd docker
docker compose up --build

# Plan the dev environment against real AWS
./scripts/deploy.sh dev plan

# Apply once you're happy with the plan
./scripts/deploy.sh dev apply
```

## Roadmap / ideas for extending this

- Add WAF in front of the ALB
- Move app tier to ECS Fargate or EKS as an alternative to EC2 ASG
- Add Route 53 + health-check based failover
- Wire the [AI Cloud Log Analyzer](../ai-cloud-log-analyzer) project to this
  stack's CloudWatch log groups for automated anomaly triage

## License

MIT — use freely for learning, portfolio, or as a starting point for real
infrastructure (review and adjust security defaults for your own risk
tolerance before production use).
