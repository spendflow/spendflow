Payments.allow allowViewOwn
Payments.deny denyIfInvalidProfile

Meteor.publish 'spendflowPayments', (profileId = -1) ->
  data = Payments.find {
    owner: @userId
    profileId: profileId
  }
  data

Payments.after.insert (userId, doc) ->
  updatePaymentTargets(doc)

# Recalculate related income/expenses when payment updated
Payments.after.update (userId, doc, fieldNames, modifier) ->
  options = options or {}
  if not options.spendflowSkipAfterHooks
    # Update previous one in case they changed the income/expense being used
    updatePaymentTargets(this.previous)

  # Update current one
  updatePaymentTargets(doc)

# Recalculate related income/expenses when payment removed
Payments.after.remove (userId, doc) ->
  updatePaymentTargets(doc)

updatePaymentTargets = (payment) ->
  # The payment might be getting deleted as part of another action, so make sure the Income and Expense still actually exist before trying to remove them.
  income = Incomes.findOne(payment.incomeId)
  updateIncomeCalculations(income) if income
  # TODO: Update income envelopes that are marked paid
  # TODO: Is this still a todo?
  # TODO: I dunno. All is lost. Hopefully this will come up again eventually.
  expense = Expenses.findOne(payment.expenseId)
  updateExpenseCalculations(expense) if expense

Meteor.methods {
  markAllEnvelopePaymentsPaid: (envelopeId) ->
    # Make sure they actually own this Envelope.
    if (Envelopes.findOne envelopeId).owner is Meteor.userId()
      envelopePayments = getPayableEnvelopePayments(envelopeId)
      paymentIds = _.pluck(envelopePayments, '_id')

      Payments.update({ _id: { $in: paymentIds } },
      { $set: { paid: true } },
      { multi: true }
      )
    else
      throw new Meteor.Error(403, 'Access denied.')
}
