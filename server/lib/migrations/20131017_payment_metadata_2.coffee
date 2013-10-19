Meteor.startup ->
  if not Migrations.findOne({name: "20131017_payment_metadata_2"})
    console.log "Running migration: 20131017_payment_metadata_2"

    console.log "Incomes..."
    # Really lazy migration. Just re-saves all Income and Expenses; the system does the work
    Incomes.find().forEach((income) ->
      updatePaymentsUsingIncome(income._id)
    )

    console.log "Expenses..."
    Expenses.find().forEach((expense) ->
      updatePaymentsUsingExpense(expense._id)
    )

    Migrations.insert({name: "20131017_payment_metadata_2"})

    console.log "Migration complete."
