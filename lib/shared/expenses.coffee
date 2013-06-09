"""
parentContext is basically the server publish function context (this).
"""
@getExpenses = (userId, parentContext, extraCriteria = {}) ->
  if not userId then userId = getCurrentUserId(parentContext)

  criteria = _.extend { owner: userId }, extraCriteria

  data = Expenses.find(criteria).fetch()
  data

@getExpenseDescription = (expenseId) ->
  expense = Expenses.findOne(expenseId) || {}
  expense.description
