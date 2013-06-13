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
      # TODO: Figure out how to get the previous income object out of the previous array
      # updateIncomeEnvelopes(income, previousIncome)
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
      applyNewIncomeEnvelopes income if income
    # when "update"
    #   income = data.income
    #   previous = data.previous

    #   applyNewIncomeEnvelopes(income, previous) if income and previous

@applyNewIncomeEnvelopes = (income = {}, previous = {}) ->
  currentEnvIds = _.keys (income.envelopes || {})
  prevEnvIds = _.keys (previous.envelopes || {})

  newEnvIds = currentEnvIds # if inserting Income

  if not _.isEmpty previous # if updating Income
    newEnvIds = []
    # Figure out what's new. withoutParams is because _.without takes *values as it second argument.
    withoutParams = [
      currentEnvIds,
    ]
    withoutParams.push id for id in prevEnvIds
    newEnvIds = _.without.apply withoutParams

  # Insert them!
  # TODO: Check if they already exist first.
  _.each(newEnvIds, (envId) ->
    envelope = Envelopes.findOne envId
    va = getVirtualAccounts(envelope.owner, undefined, { _id: envelope.virtualAccountId })[0]

    # Get the envelope amount
    amount = getEnvelopeAmount(envelope, income.amount)

    # Get if the VirtualAccount is business or not
    business = va.business

    # Create an expense for that amount
    expenseId = Expenses.insert {
      type: 'system',
      systemMeta: {
        from: 'envelope'
        fromRecordId: envelope._id
        relatedRecordId: income._id
      }
      dueDate: income.receiptDate
      description: "Envelope commitment: #{envelope.rate}% of #{income.description} goes to #{va.name}"
      amount: amount
      business: business
      oneTime: false # For now; may change when Reports develop
      destinationAccountId: va._id
      payFromAccounts: null # The whole point is that this is paid from the Income itself.
      priority: 4 # These are managed by the system, so we don't want other automated routines getting in our way
      notes: "Managed automatically"
      amountRemaining: amount # Will get updated by the Expenses insert hook
    }

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
      notes: "Managed automatically"
    }
  )
