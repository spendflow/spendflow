Incomes.allow allowViewOwn

Meteor.publish 'spendflowIncomes', ->
  data = Incomes.find { owner: @userId }
  data