Template.paymentList.payments = ->
  payments = Payments.find(
    {},
    { sort:
      {
        paid: 1
        _incomeTransferred: -1
        _expenseDueDate: 1
        _incomeReceiptDate: 1
      }
    }).fetch()

Template.paymentList.editingPayment = ->
  payment = Payments.findOne(Session.get 'editingPayment') if Session.get 'editingPayment'
  payment

Template.payment.thisRowBeingEdited = ->
  Session.equals('editingPayment', this._id)

Template.payment.amount = ->
  accounting.formatMoney @amount

Template.payment.expense = ->
  if @expenseId
    expense = Expenses.findOne @expenseId
    if expense
      expense.dueDate = formatDate expense.dueDate
      expense.destinationAccount = getVirtualAccountName(expense.destinationAccountId)
      expense
    else {}

Template.payment.income = ->
  if @incomeId
    income = Incomes.findOne @incomeId
    if income
      income.receiptDate = formatDate(income.receiptDate)
      income.depositAccount = getVirtualAccountName(income.depositAccountId)
      income
    else {}

Template.payment.events {
  'click .edit-payment': (event) ->
    event.preventDefault()
    paymentId = recordIdFromRow event
    Session.set 'editingPayment', paymentId

  'click .remove-payment': (event) ->
    event.preventDefault()
    paymentId = recordIdFromRow event
    payment = Payments.findOne(paymentId)
    expense = Expenses.findOne(payment.expenseId)
    income = Incomes.findOne(payment.incomeId)
    paymentAmount = accounting.formatMoney payment.amount
    expenseDescription = expense.description
    incomeDescription = income.description

    alertify.confirm "Are you sure you want to remove this payment of #{paymentAmount} from <em>#{incomeDescription}</em> for <em>#{expenseDescription}</em>?", (event) ->
      if event
        Payments.remove paymentId, (error) ->
          if not error
            showNavSuccess "Payment removed."
          else
            showNavError "I couldn't remove the payment for some reason. Try again, and contact us if the problems persist."
            console.log error
  'click .mark-paid': (event) ->
    event.preventDefault()
    payment = Payments.findOne(recordIdFromRow event)
    Payments.update payment._id, {
      $set: {
        paid: ! payment.paid
      }
    }, (error, result) ->
      if error
        showNavError "Something went wrong marking that paid. Try again, and contact us if it keeps happening."
        console.log error
}

Template.newPaymentForm.paymentsCount = ->
  !! Payments.find({}, { reactive: false }).count()

Template.paymentForm.expenses = ->
  expenses = getExpenses undefined, undefined, {
    $or: [
      { amountRemaining: { $ne: 0 } }
      { _id: @expenseId }
    ]
  }
  # TODO: Make this use some function with customizable optionText (perhaps via a callback)
  selectExpenses = []
  for expense in expenses
    if Math.abs(accounting.formatMoney(expense.amountRemaining)) isnt 0.00
      expense.dueDate = formatDate expense.dueDate
      ear = accounting.formatMoney expense.amountRemaining
      ea = accounting.formatMoney expense.amount
      selectExpenses.push {
        optionValue: expense._id
        optionText: "#{expense.dueDate} — #{expense.description} (#{ear} of #{ea} remaining)"
        selected: if expense._id is @expenseId then true else false
      }
  selectExpenses

Template.paymentForm.incomes = ->
  incomes = getIncomes undefined, undefined, {
    $or: [
      { amountRemaining: { $ne: 0 } }
      { _id: @incomeId }
    ]
  }
  # TODO: Make this use some function with customizable optionText (perhaps via a callback)
  selectIncomes = []
  for income in incomes
    if Math.abs(accounting.formatMoney(income.amountRemaining)) isnt 0.00
      income.receiptDate = formatDate income.receiptDate
      iar = accounting.formatMoney income.amountRemaining
      ia = accounting.formatMoney income.amount
      selectIncomes.push {
        optionValue: income._id
        optionText: "#{income.receiptDate} — #{income.description} (#{iar} of #{ia} remaining)"
        selected: if income._id is @incomeId then true else false
      }
  selectIncomes

_filledPaymentAmount = undefined
Template.paymentForm.events {
  'click .add-payment': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.add-record-form')

    paymentValues = _.extend({ type: 'manual' }, parsePaymentForm $context)

    # Sanitize the data a bit
    paymentValues.amount = +paymentValues.amount

    # TODO: Don't forget about the tags!

    # Validate
    if not paymentValues.incomeId or not paymentValues.expenseId or not paymentValues.amount or isNaN paymentValues.amount
      showNavError("To add a payment entry, you have to select an expense to pay, income to pay it with, and enter an amount.")
      return

    Payments.insert paymentValues, (error, result) ->
      if not error
        clearFormFields $context
        showNavSuccess "New payment added."
      else
        showNavError "There was a problem adding the new payment. Please try again. If the problem persists, contact us."
        console.log error

  'click .save-payment': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.edit-record-form')
    paymentId = recordIdFromForm event

    paymentValues = _.extend({ type: 'manual' }, parsePaymentForm $context)

    # Sanitize the data a bit
    paymentValues.amount = +paymentValues.amount

    # TODO: Don't forget about the tags!

    # Validate
    if not paymentValues.incomeId or not paymentValues.expenseId or not paymentValues.amount or isNaN paymentValues.amount
      showNavError("To add a payment entry, you have to select an expense to pay, income to pay it with, and enter an amount.")
      return

    Payments.update paymentId, {
      $set: paymentValues
    }, (error, result) ->
      if not error
        clearFormFields $context
        showNavSuccess "Payment updated."
        Session.set 'editingPayment', null
      else
        showNavError "There was a problem updating the payment. Please try again. If the problem persists, contact us."
        console.log error

  'click .cancel-editing': (event) ->
    event.preventDefault();
    Session.set 'editingPayment', null

  'change [name="incomeId"], change [name="expenseId"]': (event) ->
    $context = $(event.target).parents('.add-record-form')
    expenseId = valByName('expenseId', $context)
    incomeId = valByName('incomeId', $context)
    currentAmount = valByName('amount', $context)
    $amount = elementByName('amount', $context)

    if expenseId then expense = Expenses.findOne expenseId
    if incomeId then income = Incomes.findOne incomeId

    # Only fill in an amount if either we filled it in last time
    # (what we stored for the previous selection is the same
    # as what's in there)
    # or there is nothing currently filled in
    if expense and income
      elementByName('amount', $context).focus()

      if currentAmount and currentAmount isnt _filledPaymentAmount
        # Bail.
        return;

      maxAmount = accounting.toFixed(getPayableAmount expense, income)

      $amount.val(_filledPaymentAmount = maxAmount)
}

parsePaymentForm = ($context) ->
  ifp = new FormProcessor $context

  parsedForm = {
    expenseId: ifp.valByName('expenseId')
    incomeId: ifp.valByName('incomeId')
    amount: ifp.valByName('amount')
    paid: ifp.checkboxStateByName('paid')
    notes: ifp.valByName('notes')
  }
  parsedForm
