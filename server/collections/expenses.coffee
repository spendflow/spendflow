Expenses.allow allowViewOwn
Expenses.deny denyIfInvalidProfile

Meteor.publish 'spendflowExpenses', (profileId = -1) ->
  data = Expenses.find {
    owner: @userId
    profileId: profileId
  }
  data

Expenses.after "update", (userId, selector, modifier, options, previous, callback) ->
  # Don't run this if we're already inside the hook
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Get the IDs of updated records
    Expenses.find(selector).forEach((expense) ->
      updateExpenseCalculations(expense)
      updatePaymentsUsingExpense(expense._id)
    )

Expenses.before "remove", (userId, selector, previous) ->
  # Remove payments referencing this Expense
  _.each(Expenses.find(selector).fetch(), (expense) ->
    Payments.remove({ expenseId: expense._id })
  )

@updateExpenseCalculations = (expense) ->
  # Update amountRemaining and hope it doesn't loop forever
  Expenses.update(expense._id, {
    $set: {
      amountRemaining: calculateExpenseRemaining(expense)
    },
  },
    # TODO: Ensure the client can't pass this option
  { spendflowSkipAfterHooks: true })
  
@updatePaymentsUsingExpense = (expenseId) ->
  newPayments = []
  Payments.find({ expenseId: expenseId }).forEach((payment) ->
    addPaymentMetadata(payment)
    newPayments.push payment
  )

  # Update just the metadata fields to avoid race conditions, at least somewhat
  for np in newPayments
    setArguments = {}
    for sa in paymentExpenseFields
      setArguments[sa] = np[sa]

    Payments.update np._id, { $set: setArguments }, { spendflowSkipAfterHooks: true }
