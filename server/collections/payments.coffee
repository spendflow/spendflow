Payments.allow allowViewOwn

Meteor.publish 'spendflowPayments', ->
  data = Payments.find { owner: @userId }
  data
