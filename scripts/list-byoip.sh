#!/usr/bin/env bash
# List all BYOIP prefixes across all AWS regions with status and ASN
#
# Usage: ./scripts/list-byoip.sh [--profile <profile>]

set -euo pipefail

PROFILE_ARG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE_ARG="--profile $2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--profile <profile>]" >&2
      exit 1
      ;;
  esac
done

printf "%-20s %-25s %-15s %s\n" "REGION" "CIDR" "STATE" "ASN"
printf "%-20s %-25s %-15s %s\n" "------" "----" "-----" "---"

for region in $(aws ec2 describe-regions $PROFILE_ARG --query 'Regions[].RegionName' --output text); do
  results=$(aws ec2 describe-byoip-cidrs --max-results 100 --region "$region" $PROFILE_ARG \
    --query 'ByoipCidrs[].[Cidr,State,AsnAssociations[0].Asn]' --output text 2>/dev/null || true)
  if [ -n "$results" ]; then
    while IFS=$'\t' read -r cidr state asn; do
      printf "%-20s %-25s %-15s %s\n" "$region" "$cidr" "$state" "${asn:-N/A}"
    done <<< "$results"
  fi
done
