Incomes.allow allowViewOwn

Meteor.publish 'spendflowIncomes', ->
  data = Incomes.find { owner: @userId }
  data

Incomes.after "insert", (userId, doc) ->
  updateIncomeEnvelopes({ income: doc })

# Calculations
Incomes.after "update", (userId, selector, modifier, options, previous, callback) ->
  # Don't run this if we're already inside the hook
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Get the IDs of updated records
    Incomes.find(selector).forEach((income) ->
      updateIncomeCalculations(income)

      previousIncome = _.where(previous, { _id: income._id })[0];
      updateIncomeEnvelopes({
        income: income
        previous: previousIncome
      }, "update")
    )

Incomes.before "remove", (userId, selector, previous) ->
  # Remove automatically-created Envelope expenses/payments
  # We only need to remove Expenses because those automatically remove associated Payments.
  _.each(Incomes.find(selector).fetch(), (income) ->
    # fromRecordId varies, but relatedRecord is always the Income
    Expenses.remove { 'systemMeta.relatedRecordId': income._id }
  )

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
        type: 'system',
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
