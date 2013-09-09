Payments.allow allowViewOwn
Payments.deny denyIfInvalidProfile

Meteor.publish 'spendflowPayments', (profileId = -1) ->
  data = Payments.find {
    owner: @userId
    profileId: profileId
  }
  data

Payments.after.insert (userId, doc) ->
  updatePaymentTargets(doc)

# Recalculate related income/expenses when payment updated
Payments.after.update (userId, doc, fieldNames, modifier) ->
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Update previous one in case they changed the income/expense being used
    updatePaymentTargets(this.previous)

  # Update current one
  updatePaymentTargets(doc)

# Recalculate related income/expenses when payment removed
Payments.after.remove (userId, doc) ->
  updatePaymentTargets(doc)

updatePaymentTargets = (payment) ->
  # The payment might be getting deleted as part of another action, so make sure the Income and Expense still actually exist before trying to remove them.
  income = Incomes.findOne(payment.incomeId)
  updateIncomeCalculations(income) if income isnt null
  # TODO: Update income envelopes that are marked paid
  # TODO: Is this still a todo?
  expense = Expenses.findOne(payment.expenseId)
  updateExpenseCalculations(expense) if expense isnt null
