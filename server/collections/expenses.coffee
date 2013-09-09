Expenses.allow allowViewOwn
Expenses.deny denyIfInvalidProfile

Meteor.publish 'spendflowExpenses', (profileId = -1) ->
  data = Expenses.find {
    owner: @userId
    profileId: profileId
  }
  data

Expenses.after.update (userId, doc, fieldNames, modifier, options) ->
  # Don't run this if we're already inside the hook
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Get the IDs of updated records
    updateExpenseCalculations(doc)
    updatePaymentsUsingExpense(doc._id)

Expenses.before.remove (userId, doc) ->
  # Remove payments referencing this Expense
  Payments.remove({ expenseId: doc._id })

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
