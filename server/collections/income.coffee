Incomes.allow allowViewOwn

Meteor.publish 'spendflowIncomes', ->
  data = Incomes.find { owner: @userId }
  data

# Calculations
Incomes.after "update", (userId, selector, modifier, options, previous, callback) ->
  # Don't run this if we're already inside the hook
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Get the IDs of updated records
    Incomes.find(selector).forEach((income) ->
      updateIncomeCalculations(income)
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
