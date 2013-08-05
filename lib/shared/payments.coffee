@getPayableAmount = (expense = {}, income = {}) ->
  if expense.amountRemaining and income.amountRemaining
    # Logic is simple here: we want the smallest number. This should work
    # even if they are the same. e.g. if 500 in income and 1000 in expense,
    # it will choose 500. The other way around and it will still choose
    # 500 (and not overallocate the income)
    Math.min expense.amountRemaining, income.amountRemaining
