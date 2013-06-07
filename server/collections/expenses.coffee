Expenses.allow allowViewOwn

Meteor.publish 'spendflowExpenses', ->
  data = Expenses.find { owner: @userId }
  data