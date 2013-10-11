Template.dashboard.envelopeAmounts = ->
  # Initiate sequence
  envelopeAmounts = []

  # Go through all the Envelopes
  Envelopes.find().forEach((envelope) ->
    data = {}

    # We start by finding Envelope Payments that are not paid but could be
    payments = getPayableEnvelopePayments(envelope._id)

    if (! _.isEmpty(payments))
      # Figure out the title and total
      data = {
        _id: envelope._id,
        title: getVirtualAccountName(envelope.virtualAccountId),
      }

      data.total = 0.0

      _.each(payments, (payment, index) ->
        data.total += payment.amount
      )

      data.total = accounting.formatMoney data.total
      envelopeAmounts.push data
  )
  envelopeAmounts

Template.dashboard.events {
  'click .mark-all-paid': (event) ->
    event.preventDefault()
    envelopeId = $(event.target).parents('a:eq(0)').attr('data-target')
    count = +(getPayableEnvelopePayments(envelopeId).length)

    alertify.confirm("You are about to mark #{count} payments paid. Please confirm this is intentional.", (event) ->
      if event then Meteor.call('markAllEnvelopePaymentsPaid', envelopeId, (error, result) ->
        if not error
          showNavSuccess("All envelope payments marked paid.")
      )
    )
}

Template.index.events {
  'click .show-setup-help': (event) ->
    event.preventDefault()
    Meteor.users.update Meteor.userId(), { $unset: { 'profile.hideSetupHelp': 1 } }
}
