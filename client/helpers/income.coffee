Template.incomeList.incomes = ->
  Incomes.find().fetch()

Template.incomeList.editingIncome = ->
  income = Incomes.findOne(Session.get 'editingIncome') if Session.get 'editingIncome'
  income

Template.incomeRecord.thisRowBeingEdited = ->
  Session.equals('editingIncome', this._id)

Template.incomeRecord.amount = ->
  accounting.formatMoney @amount

Template.incomeRecord.envelopeAmounts = ->
  envelopeAmounts = []
  _.each(@envelopes, (env, envId) =>
    envData = Envelopes.findOne envId || {}
    va = VirtualAccounts.findOne(envData.virtualAccountId)
    envelopeAmounts.push {
      envelopeAmount: accounting.formatNumber(calculateEnvelopeAmount envData.rate, @amount, env.amountOverride, { precision: spendflowPrecision })
      envelopeName: if va then va.name else "(unnamed account)"
      envelopeRate: envData.rate
      amountOverridden: !! env.amountOverride
    }
  )
  envelopeAmounts

Template.incomeRecord.depositAccount = ->
  virtualAccount = VirtualAccounts.findOne this.depositAccountId
  virtualAccount.name if virtualAccount

Template.incomeRecord.events {
  'click .edit-income': (event) ->
    incomeId = recordIdFromRow event
    Session.set 'editingIncome', incomeId
  'click .remove-income': (event) ->
    incomeId = recordIdFromRow event
    Incomes.remove incomeId, (error) ->
      if not error
        showNavSuccess "Income removed."
      else
        showNavError "I couldn't remove the income for some reason. Try again, and contact us if problems persist."
        console.log error
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
  envelopesInUse = if @envelopes then @envelopes else {}
  getActiveEnvelopes(undefined, undefined, Object.keys envelopesInUse).forEach((envelope) =>
    # Not the same as envelopesInUse above
    envelopeInUse = @envelopes and @envelopes[envelope._id]
    if envelopeInUse
      envelope.envelopeInUse = true
      envelope.envelopeAmount = @envelopes[envelope._id].amountOverride || ""
    envelope.virtualAccount = getVirtualAccountName envelope.virtualAccountId
    massaged.push envelope
  )
  massaged

Template.incomeForm.bankAccounts = ->
  virtualAccounts = getVirtualAccounts undefined, undefined, { type: "bank" }
  getAccountSelector virtualAccounts, this.depositAccountId

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

    # Prep envelopes
    _.each(incomeValues.envelopes, (env) ->
      env.paid = false
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
  'click .save-income': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.edit-record-form')
    incomeId = recordIdFromForm event

    incomeValues = _.extend(
      {
        type: 'manual'
      },
      parseIncomeForm $context
    )

    # Prep new envelopes
    _.each(incomeValues.envelopes, (env) ->
      env.paid = false if not env.paid
    )

    # Sanitize the data a bit
    incomeValues.amount = +incomeValues.amount

    # Initialize system-managed fields
    # TODO: Recalculate the below when saving an update
    incomeValues.amountRemaining = incomeValues.amount if not incomeValues.amountRemaining
    incomeValues.pendingPaymentTotal = 0.0 if not incomeValues.pendingPaymentTotal
    incomeValues.nonBusinessTotal = 0.0 if not incomeValues.nonBusinessTotal

    # TODO: Don't forget about the tags!

    # Validate
    if not incomeValues.receiptDate or not incomeValues.description or not incomeValues.amount or isNaN incomeValues.amount
      showNavError("To add an income entry, you have to fill out the date from which it can be used, describe it, and enter an amount. Most of the time, you should pick the physical account where the income will arrive as well.")
      return

    # TODO: MVP / QUIT COPYING THIS! MAKE A COMMON FORM-SAVING PATTERN!
    Incomes.update incomeId, {
      $set: incomeValues
    }, (error, result) ->
      if not error
        $('input, select, textarea', $('.edit-record-form')).val("")
        showNavSuccess "<em>#{incomeValues.description}</em> updated."
        Session.set 'editingIncome', null
      else
        showNavError "There was a problem updating <em>#{incomeValues.description}</em>. Please try again. If the problem persists, contact us."
        console.log error

  'click .cancel-editing': (event) ->
    event.preventDefault()
    Session.set 'editingIncome', null
}

parseIncomeForm = ($context) ->
  ifp = new FormProcessor $context

  # TODO: Set up the envelopes object appropriately
  envelopes = parseEnvelopes ifp

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

parseEnvelopes = (formProcessor) ->
  envelopes = {}

  _.each(formProcessor.selectedCheckboxValues("envelopes"), (env) ->
    envelopes[env] = {
      _id: env
      amountOverride: null
    }

    amountOverride = $("##{env}").find("[name=\"envelopeAmounts\\[\\]\"]:eq(0)", formProcessor.$context).attr('value')

    if amountOverride then envelopes[env].amountOverride = amountOverride
  )

  envelopes

