"""
parentContext is basically the server publish function context (this).
"""
@getIncomes = (userId, parentContext, extraCriteria = {}, options = { sort: { receiptDate: 1 } }) ->
  if not userId then userId = getCurrentUserId(parentContext)

  criteria = _.extend { owner: userId }, extraCriteria

  data = Incomes.find(criteria, options).fetch()

  data

@getIncomeDescription = (incomeId) ->
  income = Incomes.findOne(incomeId) || {}
  income.description

@calculateIncomeRemaining = (income) ->
  # Simply subtract all payments where the income is used from the amount
  incomePayments = _.pluck(Payments.find({ incomeId: income._id }).fetch(), 'amount')

  if incomePayments.length
    +income.amount - _.reduce(incomePayments, ((memo, num) ->
      +memo + +num
    ), 0)
  else
    +income.amount

@getIncomeBusinessTotal = (income) ->
  bizTotal = +0.0
  Payments.find({ incomeId: income._id }).forEach((payment) ->
    # Get the expense
    expense = Expenses.findOne payment.expenseId

    if expense
      # If it's business, add to the bizTotal
      if expense.business then bizTotal += +payment.amount
  )
  bizTotal

@getIncomePersonalTotal = (income) ->
  total = +0.0
  Payments.find({ incomeId: income._id }).forEach((payment) ->
    # Get the expense
    expense = Expenses.findOne payment.expenseId

    if expense
      # If it's business, add to the bizTotal
      if not expense.business then total += +payment.amount
  )
  total
