#!/bin/bash
# Convenience wrapper for local terraform plan/apply against an environment.
# Usage: ./scripts/deploy.sh <dev|prod> <plan|apply|destroy>
set -euo pipefail

ENVIRONMENT="${1:?Usage: $0 <dev|prod> <plan|apply|destroy>}"
ACTION="${2:?Usage: $0 <dev|prod> <plan|apply|destroy>}"

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Environment must be 'dev' or 'prod'"
  exit 1
fi

cd "$(dirname "$0")/../terraform/environments/$ENVIRONMENT"

terraform init

case "$ACTION" in
  plan)
    terraform plan
    ;;
  apply)
    terraform apply
    ;;
  destroy)
    terraform destroy
    ;;
  *)
    echo "Action must be 'plan', 'apply', or 'destroy'"
    exit 1
    ;;
esac
