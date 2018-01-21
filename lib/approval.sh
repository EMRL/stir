#!/usr/bin/env bash
#
# approval.sh
#
###############################################################################
# Handles deployment approval queue
###############################################################################
trace "Loading approval functions"   

function queue() {
  # Make sure there's something to do
  gitStatus
  gitCommit
  #(git status --porcelain | sed '/^ D /d' | sed s/^...//) >> "${WORKPATH}/${APP}/.queued"
  (git status --porcelain | sed s/^...//) >> "${WORKPATH}/${APP}/.queued"

  info "Queuing proposed updates for approval"
  safeExit
  # slackPost
}

function approve() {
  info "Approving proposed updates"
  # Read proposed commit message from the first line of .queued
  notes="$(head -n 1 ${WORKPATH}/${APP}/.queued)"
  # Remove first line
  sed -i -e "1d" "${WORKPATH}/${APP}/.queued"
  # Loop through file, git add each file (line)
  while read QUEUED; do
    # Verify file date is older than .queued
    if [[ "${QUEUED}" -nt "${WORKPATH}/${APP}/.queued" ]]; then
      error "The file ${QUEUED} was modified after it was queued for approval."
      sed -i '1s/^/${notes}\n/' "${QUEUED}"
    else
      git add "${QUEUED}" | tee --append "${logFile}"
    fi
  done < "${WORKPATH}/${APP}/.queued"
  git commit -m "${notes}" &>> "${logFile}"; error_check
  trace "Commit message: ${notes}"
}

function deny() {
  info "Denying proposed updates"
  if [[ -f "${WORKPATH}/${APP}/.queued" ]]; then 
    rm "${WORKPATH}/${APP}/.queued"
  fi
  quietExit
}
