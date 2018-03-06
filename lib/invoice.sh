#!/usr/bin/env bash
#
# invoice.sh
#
###############################################################################
# Handles creating invoices and integration with InvoiceNinja 
###############################################################################

# Initialize variables
read -r IN_HOST IN_TOKEN IN_CLIENT_ID IN_PRODUCT IN_ITEM_COST IN_ITEM_QTY \
  IN_NOTES invoice_hack <<< ""
echo "${IN_HOST} ${IN_TOKEN} ${IN_CLIENT_ID} ${IN_PRODUCT} ${IN_ITEM_COST}
  ${IN_ITEM_QTY} ${IN_NOTES} ${invoice_hack}" > /dev/null

function create_invoice() {
  # Will create the invoice payload
  trace "Creating invoice..."
  invoice_hack=$(echo "curl -X POST \"${IN_HOST}/api/v1/invoices\" -H \"Content-Type:application/json\" -d '{\"client_id\":\"${IN_CLIENT_ID}\", \"invoice_items\":[{\"product_key\": \"${IN_PRODUCT}\", \"notes\":\"${IN_NOTES}\", \"cost\":${IN_ITEM_COST}, \"qty\":1}]}' -H \"X-Ninja-Token: ${IN_TOKEN}\"")
  eval "${invoice_hack}" &>> "${logFile}"; error_check
  safeExit
}

function get_current_invoice() {
  trace "This is an empty function"
}

function send_invoice() {
  # curl -X POST ninja.test/api/v1/email_invoice -d '{"id":1}' -H "Content-Type:application/json" -H "X-Ninja-Token: TOKEN"
  trace "This is an empty function"
}

function download_invoice() {
  # curl -X GET ninja.test/api/v1/download/1 -H "X-Ninja-Token: TOKEN"
  trace "This is an empty function"
}
