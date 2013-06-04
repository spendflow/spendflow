Template.incomeList.incomes = ->
  Incomes.find().fetch()

Template.incomeList.editingIncome = ->
  income = Incomes.findOne(Session.get 'editingIncome') if Session.get 'editingIncome'
  income
  
Template.incomeRecord.thisRowBeingEdited = ->
  Session.equals('editingIncome', this._id)

Template.incomeRecord.events {
  'click .edit-income': (event) ->
    incomeId = recordIdFromRow event
    Session.set 'editingIncome', incomeId
}

Template.newIncomeForm.incomesCount = ->
  !! Incomes.find().count()

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
    event.preventDefault()
    $context = $(event.target).parents('.add-record-form')

    incomeValues = _.extend(
      {
        type: 'manual'
      },
      parseIncomeForm $context
    )

    # Sanitize the data a bit
    incomeValues.amount = +incomeValues.amount

    # Initialize system-managed fields
    incomeValues.amountRemaining = incomeValues.amount
    incomeValues.pendingPaymentTotal = 0.0
    incomeValues.nonBusinessTotal = 0.0

    # TODO: Don't forget about the tags!

    # Validate
    if not incomeValues.receiptDate or not incomeValues.description or not incomeValues.amount or isNaN incomeValues.amount
      showNavError("To add an income entry, you have to fill out the date from which it can be used, describe it, and enter an amount. Most of the time, you should pick the physical account where the income will arrive as well.")
      return
    
    Incomes.insert incomeValues, (error, result) ->
      if not error
        $('input, select, textarea', $('.add-record-form')).val("")
        showNavSuccess "New income added."
      else
        showNavError "There was a problem adding the new income. Please try again. If the problem persists, contact us."
        console.log error
  'click .cancel-editing': (event) ->
    event.preventDefault()
    Session.set 'editingIncome', null
}

parseIncomeForm = ($context) ->
  ifp = new FormProcessor $context

  # TODO: Set up the envelopes object appropriately
  envelopes = {};

  parsedForm = {
    receiptDate: ifp.valByName('receiptDate')
    description: ifp.valByName('description')
    amount: ifp.valByName('amount')
    envelopes: envelopes
    transferred: ifp.checkboxStateByName('transferred')
    business: ifp.checkboxStateByName('business')
    depositAccountId: ifp.valByName('depositAccountId')
    notes: ifp.valByName('notes')
  }
  parsedForm
