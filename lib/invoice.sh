#!/bin/bash
#
# invoice.sh
#
###############################################################################
# Handles creating invoices and integration with InvoiceNinja 
###############################################################################

function create_invoice() {
  # Will create the invoice payload
  trace "This is an empty function"
}

function send_invoice() {
  # Hit the InvoiceNinja API and create the invoice
  # 
  # Things that need to be defined:
  # API URL
  # client_id
  #
  # And then we'll loop through
  # product
  # notes  
  # cost
  # qty
  #
  # Example to create an invoice:
  #
  # curl -X POST https://invoice.com/api/v1/invoices -H "Content-Type:application/json" \
  # -d '{"client_id":"1", "invoice_items":[{"product_key": "ITEM", "notes":"Test", "cost":10, "qty":1}]}' \
  # -H "X-Ninja-Token: ###################################"
  trace "This is an empty function"
}