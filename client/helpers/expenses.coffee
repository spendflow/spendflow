Template.expenseList.expenses = ->
  Expenses.find().fetch()

Template.expenseList.editingExpense = ->
  expense = Expenses.findOne(Session.get 'editingExpense') if Session.get 'editingExpense'
  expense

Template.expense.thisRowBeingEdited = ->
  Session.equals('editingExpense', this._id)
  
Template.expense.amount = ->
  accounting.formatMoney @amount

Template.expense.amountRemaining = ->
  accounting.formatMoney @amountRemaining

Template.expense.destinationAccount = ->
  getVirtualAccountName(@destinationAccountId)

Template.expense.payFromAccounts = ->
  massaged = []
  getVirtualAccounts(undefined, undefined, {
    type: 'payFrom'
    _id: {
      $in: Object.keys(@payFromAccounts || {})
    }
  }).forEach((pfa) =>
    pfa.accountName = getVirtualAccountName(pfa._id)
    massaged.push pfa
  )
  massaged

Template.expense.events {
  'click .edit-expense': (event) ->
    expenseId = recordIdFromRow event
    Session.set 'editingExpense', expenseId

  'click .remove-expense': (event) ->
    expenseId = recordIdFromRow event
    description = Expenses.findOne(expenseId).description

    alertify.confirm "Are you sure you want to remove <em>#{description}</em>?", (event) ->
      if event
        Expenses.remove expenseId, (error) ->
          if not error
            showNavSuccess "Expense removed."
          else
            showNavError "I couldn't remove the expense for some reason. Try again, and contact us if the problems persist."
            console.log error
}

Template.newExpenseForm.expensesCount = ->
  !! Expenses.find().count()

Template.expenseForm.rendered = ->
  $context = $ @firstNode
  $dueDate = (elementByName 'dueDate', $context)
  $dueDate.datepicker()

Template.expenseForm.destinationAccounts = ->
  virtualAccounts = getVirtualAccounts undefined, undefined, {
    type: {
      $in: [ "payFrom", "payTo", "bank" ]
    }
  }
  getAccountSelector virtualAccounts, this.destinationAccountId
  
Template.expenseForm.payFromAccounts = ->
  massaged = []
  getVirtualAccounts(undefined, undefined, {
    type: "payFrom"
  }).forEach((payFromAccount) =>
    # Not the same as payFromAccountsInUse above
    payFromAccountInUse = @payFromAccounts and @payFromAccounts[payFromAccount._id]
    if payFromAccountInUse
      payFromAccount.accountInUse = true
    payFromAccount.virtualAccount = getVirtualAccountName payFromAccount._id
    massaged.push payFromAccount
  )
  massaged

Template.expenseForm.events {
  'click .add-expense': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.add-record-form')

    expenseValues = _.extend({
      type: 'manual'
    },
      parseExpenseForm $context)

    # Prep payFromAccounts
    _.each(expenseValues.payFromAccounts, (pfa) ->
      pfa.amount = null
      pfa.paid = false
    )

    # Sanitize the data a bit
    expenseValues.amount = +expenseValues.amount

    # Initialize system-managed fields
    expenseValues.amountRemaining = expenseValues.amount

    # TODO: Don't forget about the tags!

    # Validate
    if not expenseValues.dueDate or not expenseValues.description or not expenseValues.amount or isNaN expenseValues.amount
      showNavError("To add an expense entry, you have to fill out the date from which it can be used, describe it, and enter an amount.")
      return

    Expenses.insert expenseValues, (error, result) ->
      if not error
        $('input, select, textarea', $('.add-record-form')).val("")
        showNavSuccess "New expense added."
      else
        showNavError "There was a problem adding the new expense. Please try again. If the problem persists, contact us."
        console.log error

  'click .save-expense': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.edit-record-form')
    expenseId = recordIdFromForm event

    expenseValues = _.extend({ type: 'manual' }, parseExpenseForm $context)

    # Prep new payFromAccounts
    _.each(expenseValues.payFromAccounts, (pfa) ->
      pfa.amount = null if not pfa.amount
      pfa.paid = false if not pfa.paid
    )

    # Sanitize the data a bit
    expenseValues.amount = +expenseValues.amount

    # Initialize system-managed fields
    expenseValues.amountRemaining = expenseValues.amount if not expenseValues.amountRemaining

    # TODO: Don't forget about the tags!

    # Validate
    if not expenseValues.dueDate or not expenseValues.description or not expenseValues.amount or isNaN expenseValues.amount
      showNavError("To add an expense entry, you have to fill out the date from which it can be used, describe it, and enter an amount.")
      return

    Expenses.update expenseId, {
      $set: expenseValues
    }, (error, result) ->
      if not error
        $('input, select, textarea', $('.add-record-form')).val("")
        showNavSuccess "<em>#{expenseValues.description}</em> updated."
        Session.set 'editingExpense', null
      else
        showNavError "There was a problem updating <em>#{incomeValues.description}</em>. Please try again. If the problem persists, contact us."
        console.log error

  'click .cancel-editing': (event) ->
    event.preventDefault();
    Session.set 'editingExpense', null
}

parseExpenseForm = ($context) ->
  ifp = new FormProcessor $context

  # TODO: Set up the envelopes object appropriately
  payFromAccounts = parsePayFromAccounts ifp

  parsedForm = {
    dueDate: ifp.valByName('dueDate')
    description: ifp.valByName('description')
    amount: ifp.valByName('amount')
    business: ifp.checkboxStateByName('business')
    oneTime: ifp.checkboxStateByName('oneTime')
    destinationAccountId: ifp.valByName('destinationAccountId')
    payFromAccounts: payFromAccounts
    priority: ifp.valByName('priority')
    notes: ifp.valByName('notes')
  }
  parsedForm

parsePayFromAccounts = (formProcessor) ->
  payFromAccounts = {}

  _.each(formProcessor.selectedCheckboxValues("payFromAccounts"), (pfa) ->
    payFromAccounts[pfa] = {
      _id: pfa
    }
  )

  payFromAccounts
