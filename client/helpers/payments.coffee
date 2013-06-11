Template.paymentList.payments = ->
  Payments.find().fetch()

Template.paymentList.editingPayment = ->
  payment = Payments.findOne(Session.get 'editingPayment') if Session.get 'editingPayment'
  payment

Template.payment.thisRowBeingEdited = ->
  Session.equals('editingPayment', this._id)

Template.payment.amount = ->
  accounting.formatMoney @amount

Template.payment.expense = ->
  getExpenseDescription @expenseId

Template.payment.income = ->
  getIncomeDescription @incomeId

Template.payment.events {
  'click .edit-payment': (event) ->
    paymentId = recordIdFromRow event
    Session.set 'editingPayment', paymentId

  'click .remove-payment': (event) ->
    paymentId = recordIdFromRow event
    Payments.remove paymentId, (error) ->
      if not error
        showNavSuccess "Payment removed."
      else
        showNavError "I couldn't remove the payment for some reason. Try again, and contact us if the problems persist."
        console.log error
}

Template.newPaymentForm.paymentsCount = ->
  !! Payments.find().count()

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
      optionText: "#{expense.description} (#{ear} of #{ea} remaining)"
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
      optionText: "#{income.description} (#{iar} of #{ia} remaining)"
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
        $('input, select, textarea', $('.add-record-form')).val("")
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
        $('input, select, textarea', $('.add-record-form')).val("")
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
