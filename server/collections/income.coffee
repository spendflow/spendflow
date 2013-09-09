Incomes.allow allowViewOwn
Incomes.deny denyIfInvalidProfile

Meteor.publish 'spendflowIncomes', (profileId = -1) ->
  data = Incomes.find {
    owner: @userId
    profileId: profileId
  }
  data

Incomes.after.insert (userId, doc) ->
  updateIncomeEnvelopes({ income: doc })

# Calculations
Incomes.after.update (userId, doc, fieldNames, modifier, options) ->
  # Don't run this if we're already inside the hook
  options = options or {}
  if not options.spendflowSkipAfterHooks
    updateIncomeCalculations(doc)

    previousIncome = this.previous
    updateIncomeEnvelopes({
      income: doc
      previous: previousIncome
    }, "update")

    updatePaymentsUsingIncome(doc._id)

Incomes.before.remove (userId, doc) ->
  # Remove automatically-created Envelope expenses/payments
  # We only need to remove Expenses because those automatically remove associated Payments.

  # fromRecordId varies, but relatedRecord is always the Income
  Expenses.remove { 'systemMeta.relatedRecordId': doc._id }

@updateIncomeCalculations = (income) ->
  # Update amountRemaining and hope it doesn't loop forever
  Incomes.update(income._id, {
    $set: {
      amountRemaining: calculateIncomeRemaining(income)
    },
  },
    # TODO: Ensure the client can't pass this option
  { spendflowSkipAfterHooks: true })

###
  data:
    (when mode is "insert")
      - income
    (when mode is "update")
      - income
      - previous
    (when mode is "remove")
      - previous
###
@updateIncomeEnvelopes = (data, mode = "insert") ->
  switch mode
    when "insert"
      income = data.income
      applyIncomeEnvelopes income if income
    when "update"
      income = data.income
      previous = data.previous

      applyIncomeEnvelopes(income, previous) if income and previous

@applyIncomeEnvelopes = (income = {}, previous = {}) ->
  currentEnvIds = _.keys (income.envelopes || {})
  prevEnvIds = _.keys (previous.envelopes || {})

  # Insert or update currently-set envelopes.
  # TODO: Check if they already exist first.
  _.each(currentEnvIds, (envId) ->
    envelope = Envelopes.findOne envId
    if not envelope
      console.log "Empty envelope! App is probably about to crash."
      console.log income
      console.log envId
      console.log envelope
    va = getVirtualAccounts(envelope.owner, undefined, { _id: envelope.virtualAccountId })[0]

    # Get the envelope amount
    amount = getEnvelopeAmount(income, envelope)

    # Get if the VirtualAccount is business or not
    business = va.business

    # Insert or update?
    existingExpense = Expenses.findOne {
      'systemMeta.fromRecordId': envelope._id
      'systemMeta.relatedRecordId': income._id
    }

    if not existingExpense
      # Create an expense for that amount
      expenseId = Expenses.insert {
        profileId: income.profileId
        type: 'system'
        systemMeta: {
          from: 'envelope'
          fromRecordId: envelope._id
          relatedRecordId: income._id
        }
        dueDate: income.receiptDate
        description: "#{envelope.rate}% of #{income.description} goes to #{va.name}"
        amount: amount
        business: business
        oneTime: false # For now; may change when Reports develop
        destinationAccountId: va._id
        payFromAccounts: null # The whole point is that this is paid from the Income itself.
        priority: 4 # These are managed by the system, so we don't want other automated routines getting in our way
        notes: spendflowAutomaticNotes
        amountRemaining: amount # Will get updated by the Expenses insert hook
      }
    else
      # Just fix stuff that might have changed since last time
      Expenses.update existingExpense._id, {
        $set: {
          dueDate: income.receiptDate
          description: "#{envelope.rate}% of #{income.description} goes to #{va.name}"
          amount: amount
          business: business
          notes: spendflowAutomaticNotes
        }
      }

    # Insert or update?
    existingPayment = Payments.findOne {
      'systemMeta.fromRecordId': envelope._id
      'systemMeta.relatedRecordId': income._id
    }

    if not existingPayment
      Payments.insert {
        profileId: income.profileId
        type: 'system'
        systemMeta: {
          from: 'envelope'
          fromRecordId: envelope._id
          relatedRecordId: income._id
        }
        expenseId: expenseId
        incomeId: income._id
        amount: amount
        paid: false
        notes: spendflowAutomaticNotes
      }
    else
      Payments.update existingPayment._id, {
        $set: {
          amount: amount
          notes: spendflowAutomaticNotes
        }
      }
  )

  # Remove linked Expenses/Payments for unchecked envelopes on income
  removedIds = _.difference(prevEnvIds, currentEnvIds)
  _.each(removedIds, (envId) ->
    envelope = Envelopes.findOne envId
    # Will remove dependent Payments
    Expenses.remove {
      'systemMeta.fromRecordId': envelope._id
      'systemMeta.relatedRecordId': income._id
    }
  )

@updatePaymentsUsingIncome = (incomeId) ->
  newPayments = []
  Payments.find({ incomeId: incomeId }).forEach((payment) ->
    addPaymentMetadata(payment)
    newPayments.push payment
  )

  # Update just the metadata fields to avoid race conditions, at least somewhat
  for np in newPayments
    setArguments = {}
    for sa in paymentIncomeFields
      setArguments[sa] = np[sa]

    Payments.update np._id, { $set: setArguments }, { spendflowSkipAfterHooks: true }
