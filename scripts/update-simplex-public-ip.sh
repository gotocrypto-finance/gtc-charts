#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <public-ipv4>" >&2
  echo "Environment: SIMPLEX_NAMESPACE (default: simplex), SIMPLEX_RELEASE (default: simplex-smp)" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

public_ip=$1
namespace=${SIMPLEX_NAMESPACE:-simplex}
release=${SIMPLEX_RELEASE:-simplex-smp}
deployment="${release}-simplex-smp"

if ! [[ $public_ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "Invalid IPv4 address: $public_ip" >&2
  exit 2
fi

IFS=. read -r octet1 octet2 octet3 octet4 <<< "$public_ip"
for octet in "$octet1" "$octet2" "$octet3" "$octet4"; do
  if (( 10#$octet > 255 )); then
    echo "Invalid IPv4 address: $public_ip" >&2
    exit 2
  fi
done

services=(
  "${release}-simplex-smp"
  "${release}-xftp"
  "${release}-turn"
)

patch=$(printf '{"spec":{"externalIPs":["%s"],"externalTrafficPolicy":"Cluster"}}' "$public_ip")

for service in "${services[@]}"; do
  kubectl patch service \
    --namespace "$namespace" \
    "$service" \
    --type merge \
    --patch "$patch"
done

# TURN includes the public address in the relay candidates returned to clients.
# Updating only the Service is therefore insufficient.
kubectl set env \
  --namespace "$namespace" \
  "deployment/${deployment}" \
  "PUBLIC_IP=$public_ip" \
  --containers turn

kubectl rollout status \
  --namespace "$namespace" \
  "deployment/${deployment}" \
  --timeout 180s

echo "SimpleX external IP updated to $public_ip in namespace $namespace."
