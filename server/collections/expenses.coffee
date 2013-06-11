Expenses.allow allowViewOwn

Meteor.publish 'spendflowExpenses', ->
  data = Expenses.find { owner: @userId }
  data

Expenses.after "update", (userId, selector, modifier, options, previous, callback) ->
  # Don't run this if we're already inside the hook
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Get the IDs of updated records
    Expenses.find(selector).forEach((expense) ->
      updateExpenseCalculations(expense)
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
