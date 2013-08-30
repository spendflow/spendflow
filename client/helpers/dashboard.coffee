Template.dashboard.envelopeAmounts = ->
  # Initiate sequence
  envelopeAmounts = []

  # Go through all the Envelopes
  Envelopes.find().forEach((envelope) ->
    data = {}

    # We start by finding Envelope Payments that are not paid but could be
    payments = Payments.find({
      "systemMeta.fromRecordId": envelope._id
      paid: { $ne: true }
      _incomeTransferred: true
    }).fetch()

    if (! _.isEmpty(payments))
      # Figure out the title and total
      data = {
        title: getVirtualAccountName(envelope.virtualAccountId)
      }

      data.total = 0.0

      _.each(payments, (payment, index) ->
        data.total += payment.amount
      )

      data.total = accounting.formatMoney data.total
      envelopeAmounts.push data
  )
  envelopeAmounts
