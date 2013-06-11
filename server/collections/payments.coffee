Payments.allow allowViewOwn

Meteor.publish 'spendflowPayments', ->
  data = Payments.find { owner: @userId }
  data

Payments.after "insert", (userId, doc) ->
  updatePaymentTargets(doc)

# Recalculate related income/expenses when payment updated
Payments.after "update", (userId, selector, modifier, options, previous) ->
  # Update previous ones in case they changed the income/expense being used
  _.each(previous, (payment) ->
    updatePaymentTargets(payment)
  )
  # Update current ones
  Payments.find(selector).forEach((payment) ->
    updatePaymentTargets(payment)
  )

# Recalculate related income/expenses when payment removed
Payments.after "remove", (userId, selector, previous) ->
  _.each(previous, (payment) ->
    updatePaymentTargets(payment)
  )

updatePaymentTargets = (payment) ->
  updateIncomeCalculations(Incomes.findOne payment.incomeId)
  updateExpenseCalculations(Expenses.findOne payment.expenseId)
