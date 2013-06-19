Payments.allow allowViewOwn
Payments.deny denyIfInvalidProfile

Meteor.publish 'spendflowPayments', (profileId = -1) ->
  data = Payments.find {
    owner: @userId
    profileId: profileId
  }
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
  # The payment might be getting deleted as part of another action, so make sure the Income and Expense still actually exist before trying to remove them.
  income = Incomes.findOne(payment.incomeId)
  updateIncomeCalculations(income) if income isnt null
  # TODO: Update income envelopes that are marked paid
  expense = Expenses.findOne(payment.expenseId)
  updateExpenseCalculations(expense) if expense isnt null
