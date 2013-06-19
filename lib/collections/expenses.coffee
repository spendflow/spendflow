###
Expenses
  $ - type: (manual|system) — system ones are ones created from BudgetedExpenses or Envelopes
  $ - systemMeta — more or less the same thing as with Payments. envelope or budgetedExpense? and recordId
  - dueDate
  - description
  - amount
  - business
  - oneTime
  - payToVirtualAccountId
  - payFromVirtualAccountIds (actual amounts figured out in Payments)
  - notes
  - tags
  - priority: (1|2|3|4) — 3 is default, 4 means manually, use constants
  - amountRemaining
###

@Expenses = new Meteor.Collection 'expenses'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowExpenses', getCurrentProfile()

# Hooks
@Expenses.before "insert", ensureCommonMetadata
