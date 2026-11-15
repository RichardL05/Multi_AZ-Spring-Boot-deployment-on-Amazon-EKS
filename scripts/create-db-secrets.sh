#!/usr/bin/env bash
# Create the two application Secrets from private interactive input.
# Run on the management host only after checking kubectl's current context.
set +x
set -euo pipefail

namespace="${1:-richard-springboot-app}"
command -v kubectl >/dev/null
kubectl get namespace "$namespace" >/dev/null

if [ ! -t 0 ]; then
  printf 'Run this script in an interactive terminal.\n' >&2
  exit 1
fi

printf 'Kubernetes context: %s\n' "$(kubectl config current-context)"
printf 'Target namespace: %s\n' "$namespace"
IFS= read -r -p 'Database username: ' db_username
IFS= read -r -s -p 'Database password: ' db_password
printf '\n'

if [ -z "$db_username" ] || [ -z "$db_password" ]; then
  printf 'Username and password must both be non-empty.\n' >&2
  exit 1
fi

umask 077
secret_dir="$(mktemp -d)"
cleanup() {
  rm -f -- "$secret_dir/username" "$secret_dir/password"
  rmdir -- "$secret_dir"
}
trap cleanup EXIT

printf '%s' "$db_username" > "$secret_dir/username"
printf '%s' "$db_password" > "$secret_dir/password"
unset db_username db_password

kubectl create secret generic mysql-username \
  --namespace "$namespace" \
  --from-file=username="$secret_dir/username" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic mysql-root-password \
  --namespace "$namespace" \
  --from-file=password="$secret_dir/password" \
  --dry-run=client -o yaml | kubectl apply -f -

printf 'Database Secrets created or updated; values were not printed.\n'
