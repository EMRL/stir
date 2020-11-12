#!/usr/bin/env bash
#
# invoice.sh
#
###############################################################################
# Handles creating invoices and integration with InvoiceNinja 
###############################################################################

# Initialize variables
var=(IN_CLIENT_ID IN_PRODUCT IN_ITEM_COST IN_ITEM_QTY \
  IN_NOTES IN_EMAIL invoice_hack current_invoice \
  IN_INCLUDE_REPORT IN_PUBLIC_NOTES current_invoice_offset)
init_loop

function create_invoice() {
  if [[ -z "${IN_HOST}" || -z "${IN_TOKEN}" || -z "${IN_CLIENT_ID}" || -z "${IN_PRODUCT}" || -z "${IN_ITEM_COST}" || -z "${IN_ITEM_QTY}" ]]; then
    console "Invoicing not configured correctly, can not create payload."; quiet_exit
  fi

  # Report creation is coming soon, currently bugged
  if [[ "${IN_INCLUDE_REPORT}" == "TRUE" ]]; then
    create_report
    if [[ -n "${IN_NOTES}" ]]; then
      IN_NOTES="${IN_NOTES}\n"
    fi
    IN_NOTES="${IN_NOTES}View your full monthly update report at ${REPORTURL}"
    IN_PUBLIC_NOTES="View your monthly update report at ${REPORTURL}"
  fi

  # Will create the invoice payload
  trace "Creating invoice..."
  invoice_hack=$(echo "curl -X POST \"${IN_HOST}/api/v1/invoices\" -H \"Content-Type:application/json\" -d '{\"client_id\":\"${IN_CLIENT_ID}\", \"invoice_items\":[{\"product_key\": \"${IN_PRODUCT}\", \"notes\":\"${IN_NOTES}\",\"public_notes\":\"${IN_PUBLIC_NOTES}\", \"cost\":\"${IN_ITEM_COST}\", \"qty\":\"$IN_ITEM_QTY\"}]}' -H \"X-Ninja-Token:${IN_TOKEN}\"")
  eval "${invoice_hack}" &>> "${log_file}"; error_check

  get_current_invoice
  if [[ -n "${REPORTURL}" ]]; then
    attach_pdf2invoice
  fi 

  if [[ "${IN_EMAIL}" == "TRUE" ]]; then
    send_invoice
  fi 

  clean_exit
}

function get_current_invoice() {
  "${curl_cmd}" --silent -X GET "${IN_HOST}/api/v1/clients/${IN_CLIENT_ID}?include=invoices" -H "X-Ninja-Token: ${IN_TOKEN}" > "${trash_file}"; error_check

  # Many sedtastic things
  sed -i '/"invoice_number"/!d' "${trash_file}"
  sed -i 's/ //g' "${trash_file}"
  sed -i 's/[^0-9]*//g' "${trash_file}"

  # Store current invoice number
  current_invoice=$(tail -1 ${trash_file})
  trace "Invoice ${current_invoice} created"

  # Apply an offset to the invoice number if needed
  if [[ -n "${IN_OFFSET}" ]]; then
    current_invoice_offset="$((${current_invoice}-${IN_OFFSET}))"
  fi
}

function send_invoice() {
  trace status "Emailing invoice ${current_invoice}... "
  # Build out the command to send the email
  invoice_hack=$(echo "curl -X POST ${IN_HOST}/api/v1/email_invoice -d '{\"id\":$current_invoice_offset}' -H \"Content-Type:application/json\" -H \"X-Ninja-Token: ${IN_TOKEN}\"")
  eval "${invoice_hack}" &>> "${log_file}"; error_check
  trace notime "OK"
}

function attach_pdf2invoice() {
  trace status "Attaching PDF report... "
  "${wkhtmltopdf_cmd}" "${REPORTURL}" "/tmp/${APP}_${current_year}-${current_month}.pdf" &>> "${log_file}"; error_check

  "${curl_cmd}" --silent -X POST "${IN_HOST}/api/v1/documents?invoice_id=${current_invoice_offset}" -H "Content-Type:multipart/form-data" -H "X-Requested-With: XMLHttpRequest" -H "X-Ninja-Token:${IN_TOKEN}" -F "file=@/tmp/${APP}_${current_year}-${current_month}.pdf" &>> "${log_file}"; error_check

  rm "/tmp/${APP}_${current_year}-${current_month}.pdf"
  trace notime "OK"
}
