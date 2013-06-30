"""
parentContext is basically the server publish function context (this).
"""
@getExpenses = (userId, parentContext, extraCriteria = {}, options = { sort: { dueDate: 1 } }) ->
  if not userId then userId = getCurrentUserId(parentContext)

  criteria = _.extend { owner: userId }, extraCriteria

  data = Expenses.find(criteria, options).fetch()

  data

@getExpenseDescription = (expenseId) ->
  expense = Expenses.findOne(expenseId) || {}
  expense.description

@calculateExpenseRemaining = (expense) ->
  # Simply subtract all payments where the expense is used from the amount
  expensePayments = _.pluck(Payments.find({ expenseId: expense._id }).fetch(), 'amount')
  if expensePayments.length
    +expense.amount - _.reduce(expensePayments, ((memo, num) ->
      +memo + +num
    ), 0)
  else
    +expense.amount
