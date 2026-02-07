#!/usr/bin/env bash
# Delete Cloudflare DNS records for Teleport.
# Removes both:
#   teleport.davidshaevel.com   (proxy)
#   *.teleport.davidshaevel.com (app subdomains)
# Requires: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID in .envrc

source "$(dirname "$0")/config.sh"
setup_logging "teleport-dns-delete"

DOMAIN="teleport.davidshaevel.com"
WILDCARD_DOMAIN="*.teleport.davidshaevel.com"
CF_API="https://api.cloudflare.com/client/v4"
ZONE_ID="${CLOUDFLARE_ZONE_ID:?Set CLOUDFLARE_ZONE_ID in .envrc or environment}"
API_TOKEN="${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN in .envrc or environment}"

# Look up and display existing records.
echo "Looking up DNS records for Teleport..."
FOUND=0
for name in "${DOMAIN}" "${WILDCARD_DOMAIN}"; do
    EXISTING=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?name=${name}&type=A" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")
    RECORD_IP=$(echo "${EXISTING}" | jq -r '.result[0].content // empty')
    if [ -n "${RECORD_IP}" ]; then
        echo "  ${name} -> ${RECORD_IP}"
        FOUND=$((FOUND + 1))
    fi
done

if [ "${FOUND}" -eq 0 ]; then
    echo "No DNS records found for Teleport. Nothing to delete."
    exit 0
fi

echo ""
read -r -p "Type 'delete' to confirm deletion of ${FOUND} record(s): " confirm
if [ "${confirm}" != "delete" ]; then
    echo "Confirmation failed. Aborting."
    exit 1
fi

# Delete each record.
# Usage: delete_record <record_name>
delete_record() {
    local record_name="${1}"

    local existing
    existing=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?name=${record_name}&type=A" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    local record_id
    record_id=$(echo "${existing}" | jq -r '.result[0].id // empty')

    if [ -z "${record_id}" ]; then
        echo "  ${record_name}: not found, skipping."
        return
    fi

    local result
    result=$(curl -s -X DELETE "${CF_API}/zones/${ZONE_ID}/dns_records/${record_id}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    local success
    success=$(echo "${result}" | jq -r '.success')
    if [ "${success}" = "true" ]; then
        echo "  ${record_name}: deleted."
    else
        echo "  ${record_name}: error deleting:"
        echo "${result}" | jq '.errors'
        exit 1
    fi
}

echo "Deleting DNS records..."
delete_record "${DOMAIN}"
delete_record "${WILDCARD_DOMAIN}"
echo ""
echo "All Teleport DNS records deleted."
