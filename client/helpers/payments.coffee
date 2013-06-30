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
  expense = Expenses.findOne @expenseId
  expense.dueDate = formatDate expense.dueDate
  expense.destinationAccount = getVirtualAccountName(expense.destinationAccountId)
  expense

Template.payment.income = ->
  income = Incomes.findOne @incomeId
  income.receiptDate = formatDate(income.receiptDate)
  income.depositAccount = getVirtualAccountName(income.depositAccountId)
  income

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
  for expense in expenses
    ear = accounting.formatMoney expense.amountRemaining
    ea = accounting.formatMoney expense.amount
    {
      optionValue: expense._id
      optionText: "#{expense.dueDate} — #{expense.description} (#{ear} of #{ea} remaining)"
      selected: if expense._id is @expenseId then true else false
    }

Template.paymentForm.incomes = ->
  incomes = getIncomes undefined, undefined, {
    $or: [
      { amountRemaining: { $ne: 0 } }
      { _id: @incomeId }
    ]
  }
  # TODO: Make this use some function with customizable optionText (perhaps via a callback)
  for income in incomes
    iar = accounting.formatMoney income.amountRemaining
    ia = accounting.formatMoney income.amount
    {
      optionValue: income._id
      optionText: "#{income.receiptDate} — #{income.description} (#{iar} of #{ia} remaining)"
      selected: if income._id is @incomeId then true else false
    }

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
