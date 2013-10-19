###
Payments
  $ - type: (manual|system) — system ones are, for example, when part of income is automatically used to pay Envelope-based expenses
  $ - systemMeta — an object with case-specific keys. initially probably just { from: 'envelope', recordId: envelopeId }
  - expenseId
  - incomeId
  - amount
  - paid
  - notes
   $ - _incomeTransferred
   $ - _incomeReceiptDate
   $ - _expenseDueDate
###

@Payments = new Meteor.Collection 'payments'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowPayments', getCurrentProfile()

# Hooks
@Payments.before.insert ensureCommonMetadata
@Payments.before.insert (userId, doc) ->
  addPaymentMetadata doc

# Also updates
@addPaymentMetadata = (doc) ->
  income = Incomes.findOne doc.incomeId
  expense = Expenses.findOne doc.expenseId

  # Copy some income fields to the payment so we can sort by them and also for performance
  if income
    doc._incomeTransferred = income.transferred
    doc._incomeReceiptDate = income.receiptDate
    doc._incomeDescription = income.description
    doc._incomeDepositAccountId = income.depositAccountId
    doc._incomeDepositAccount = getVirtualAccountName(income.depositAccountId)
    doc._incomeNotes = income.notes

  if expense
    doc._expenseDueDate = expense.dueDate
    doc._expenseBusiness = expense.business
    doc._expenseDescription = expense.description
    doc._expenseDestinationAccountId = expense.destinationAccountId
    doc._expenseDestinationAccount = getVirtualAccountName(expense.destinationAccountId)
    doc._expenseNotes = expense.notes

@paymentIncomeFields = [
  '_incomeTransferred'
  '_incomeReceiptDate'
  '_incomeDescription'
  '_incomeDepositAccountId'
  '_incomeDepositAccount'
  '_incomeNotes'
]
@paymentExpenseFields = [
  '_expenseDueDate'
  '_expenseBusiness'
  '_expenseDescription'
  '_expenseDestinationAccountId'
  '_expenseDestinationAccount'
  '_expenseNotes'
]
