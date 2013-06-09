"""
parentContext is basically the server publish function context (this).
"""
@getIncomes = (userId, parentContext, extraCriteria = {}) ->
  if not userId then userId = getCurrentUserId(parentContext)

  criteria = _.extend { owner: userId }, extraCriteria

  data = Incomes.find(criteria).fetch()
  data

@getIncomeDescription = (incomeId) ->
  income = Incomes.findOne(incomeId) || {}
  income.description
