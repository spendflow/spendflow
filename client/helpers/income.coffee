Template.income.incomesCount = ->
  incomesCount = Incomes.find().count()
  if incomesCount > 0 then incomesCount else false

Template.incomeForm.rendered = ->
  $context = $ this.firstNode
  $receiptDate = (elementByName 'receiptDate', $context)
  $receiptDate.datepicker()

# TODO: Make sure that enveloeps being used in the currently-edited record (or anywhere the active flag is checked) always are returned.
Template.incomeForm.envelopes = ->
  massaged = []
  getActiveEnvelopes().forEach((envelope) ->
    envelope.virtualAccount = getVirtualAccountName envelope.virtualAccountId
    massaged.push envelope
  )
  massaged

Template.incomeForm.bankAccounts = ->
  virtualAccounts = getVirtualAccounts undefined, undefined, { type: "bank" }
  getAccountSelector virtualAccounts

Template.incomeForm.events {
  'click .add-income': (event) ->

}
