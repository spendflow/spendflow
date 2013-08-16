@spendflowAutomaticNotes = "Managed automatically"

Accounts.emailTemplates.from = "Kevin at Spendflow <kevin@spendflow.co>"

if not Meteor.settings?.public?.analytics_api_key?
  console.log "Oops, looks like the Segment.io API key is missing! Analytics won't work until you fix that."
