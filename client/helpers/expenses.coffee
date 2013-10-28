Template.expenseToolbar.showCommittedExpenses = ->
  if Meteor.user().profile and Meteor.user().profile.showCommittedExpenses
    return true;
  false

Template.expenseToolbar.events {
  'click #expenses-show-committed': (event) ->
    currentStatus = Template.expenseToolbar.showCommittedExpenses()
    Meteor.users.update(Meteor.userId(), { $set: { 'profile.showCommittedExpenses' : ! currentStatus } })
}

Template.expenseList.expenses = ->
  # TODO: Make a function that respects the profile-stored options. Right now, this is only done here.
  # We can't do this server-side because we still need the Expenses to be in the data set; Payments may reference them.
  selector = { 'systemMeta.from': { $ne: 'envelope' }, amountRemaining: { $gte: 0.01 } }
  if Template.expenseToolbar.showCommittedExpenses() then delete selector.amountRemaining
  Expenses.find(selector, { sort: { dueDate:1 } }).fetch()

# TODO: Needed anymore? 17 Oct 2013
Template.expenseList.editingExpense = ->
  expense = Expenses.findOne(Session.get 'editingExpense') if Session.get 'editingExpense'
  expense

Template.expense.thisRowBeingEdited = ->
  Session.equals('editingExpense', this._id)

Template.expense.dueDate = ->
  formatDate @dueDate
  
Template.expense.amount = ->
  accounting.formatMoney @amount

Template.expense.expensePaid = ->
  # The one-cent thing again...this is the best way to deal with the weirdness of floats.
  (accounting.formatMoney @amountRemaining) < 0.01

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
    event.preventDefault()
    expenseId = recordIdFromRow event
    Session.set 'editingExpense', expenseId

  'click .copy-expense': (event) ->
    event.preventDefault()
    expenseId = recordIdFromRow event
    # Copy the expense fields to the form
    $form = $('#new-expense-form')

    continueExpenseCopy = =>
      expense = Expenses.findOne expenseId

      $form.scrollintoview({
        complete: ->
          populateExpenseForm($form, expense)
      })

    if (! $form.hasClass('in'))
      $form.collapse('show').on('shown', continueExpenseCopy)
    else
      continueExpenseCopy()

  'click .remove-expense': (event) ->
    event.preventDefault()
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
  !! Expenses.find({}, { reactive: false }).count()

Template.expenseForm.rendered = ->
  $context = $ @firstNode
  $dueDate = (elementByName 'dueDate', $context)
  $dueDate.datepicker()

Template.expenseForm.dueDate = ->
  moment(@dueDate).format("MM/DD/YYYY")

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

addExpense = (event) ->
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
      clearFormFields $context
      showNavSuccess "New expense added."
    else
      showNavError "There was a problem adding the new expense. Please try again. If the problem persists, contact us."
      console.log error

Template.expenseForm.events {
  'click .add-expense': addExpense

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
        clearFormFields $context
        showNavSuccess "<em>#{expenseValues.description}</em> updated."
        Session.set 'editingExpense', null
      else
        showNavError "There was a problem updating <em>#{incomeValues.description}</em>. Please try again. If the problem persists, contact us."
        console.log error

  'click .cancel-editing': (event) ->
    event.preventDefault();
    Session.set 'editingExpense', null

  'click .clone-to-next-week': (event) ->
    event.preventDefault()
    increaseDateAndSave event, "week"

  'click .clone-to-next-month': (event) ->
    event.preventDefault()
    increaseDateAndSave event
}

increaseDateAndSave = (event, timePeriod = "month", howMany = 1) ->
  if not _.contains(["month", "week"], timePeriod) then timePeriod = "month"

  $context = $(event.target).parents('.add-record-form')
  $datepicker = elementByName('dueDate', $context)
  dateNow = moment($datepicker.datepicker("getDate"))
  $datepicker.datepicker("setDate", (dateNow.add(howMany, timePeriod)).toDate())
  addExpense(event) # This is OK cuz the buttons have the same parent form as the regular add button

parseExpenseForm = ($context) ->
  ifp = new FormProcessor $context

  # TODO: Set up the envelopes object appropriately
  payFromAccounts = parsePayFromAccounts ifp

  parsedForm = {
    dueDate: if ifp.valByName('dueDate') then moment(ifp.valByName('dueDate'), "MM/DD/YYYY").toDate() else "" # So that validation still works
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

populateExpenseForm = ($context, expense) ->
  ifp = new FormProcessor $context

  ifp.setValByName('dueDate', moment(expense.dueDate).format('MM/DD/YYYY'))
  ifp.setValByName('description', expense.description)
  ifp.setValByName('amount', expense.amount)
  ifp.setValByName('business', expense.business)
  ifp.setValByName('oneTime', expense.oneTime)
  ifp.setValByName('destinationAccountId', expense.destinationAccountId)

  _.each(expense.payFromAccounts or {}, (value, index) =>
    $pfa = $('[name="payFromAccounts[]"][value="' + index + '"]')
    $pfa.attr('checked', '')
  )

  ifp.setValByName('priority', expense.priority)
  ifp.setValByName('notes', expense.notes)
