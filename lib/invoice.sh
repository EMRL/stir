#!/usr/bin/env bash
#
# invoice.sh
#
###############################################################################
# Handles creating invoices and integration with InvoiceNinja 
###############################################################################

# Initialize variables
var=(IN_HOST IN_TOKEN IN_CLIENT_ID IN_PRODUCT IN_ITEM_COST IN_ITEM_QTY \
  IN_NOTES IN_EMAIL invoice_hack current_invoice)
init_loop

function create_invoice() {
  if [[ -z "${IN_HOST}" || -z "${IN_TOKEN}" || -z "${IN_CLIENT_ID}" || -z "${IN_PRODUCT}" || -z "${IN_ITEM_COST}" || -z "${IN_ITEM_QTY}" ]]; then
    console "Invoicing not configured correctly, can not create payload."; quietExit
  fi    

  # Will create the invoice payload
  trace "Creating invoice..."
  invoice_hack=$(echo "curl -X POST \"${IN_HOST}/api/v1/invoices\" -H \"Content-Type:application/json\" -d '{\"client_id\":\"${IN_CLIENT_ID}\", \"invoice_items\":[{\"product_key\": \"${IN_PRODUCT}\", \"notes\":\"${IN_NOTES}\", \"cost\":${IN_ITEM_COST}, \"qty\":1}]}' -H \"X-Ninja-Token: ${IN_TOKEN}\"")
  eval "${invoice_hack}" &>> "${logFile}"; error_check

  get_current_invoice

  if [[ "${IN_EMAIL}" == "TRUE" ]]; then
    send_invoice
  fi 

  safeExit
}

function get_current_invoice() {
  curl -X GET "${IN_HOST}/api/v1/clients/${IN_CLIENT_ID}?include=invoices" -H "X-Ninja-Token: ${IN_TOKEN}" > "${trshFile}"

  # Many sedtastic things
  sed -i '/"invoice_number"/!d' "${trshFile}"
  sed -i 's/ //g' "${trshFile}"
  sed -i 's/[^0-9]*//g' "${trshFile}"

  # Store current invoice number
  current_invoice=$(tail -1 ${trshFile})
  trace "Invoice: ${current_invoice}"
}

function send_invoice() {
  # This does not seem to work as advertised. Ugh.
  # curl -X POST ninja.test/api/v1/email_invoice -d '{"id":1}' -H "Content-Type:application/json" -H "X-Ninja-Token: TOKEN"
  invoice_hack=$(echo "curl -X POST ${IN_HOST}/api/v1/email_invoice -d '{\"id\":${current_invoice}}' -H "Content-Type:application/json" -H \"X-Ninja-Token: ${IN_TOKEN}\"")
  trace "Trying ${invoice_hack}"
  eval "${invoice_hack}" &>> "${logFile}"; error_check
}
