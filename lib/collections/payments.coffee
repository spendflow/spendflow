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
@Payments.before "insert", ensureCommonMetadata
@Payments.before "insert", (userId, doc) ->
  addPaymentMetadata doc

# Also updates
@addPaymentMetadata = (doc) ->
  income = Incomes.findOne doc.incomeId
  expense = Expenses.findOne doc.expenseId

  # Copy some income fields to the payment so we can sort by them
  if income
    doc._incomeTransferred = income.transferred
    doc._incomeReceiptDate = income.receiptDate

  if expense
    doc._expenseDueDate = expense.dueDate

@paymentIncomeFields = [
  '_incomeTransferred'
  '_incomeReceiptDate'
]
@paymentExpenseFields = [
  '_expenseDueDate'
]
