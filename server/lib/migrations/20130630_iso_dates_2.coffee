Meteor.startup ->
  if not Migrations.findOne({name: "20130630_iso_dates_2"})
    console.log "Running migration: 20130630_iso_dates_2"

    # Get all income and expense dates
    incomes = Incomes.find({}, { fields: { receiptDate: 1, description: 1 } }).fetch()
    expenses = Expenses.find({}, { fields: { dueDate: 1, description: 1 } }).fetch()

    console.log '====== INCOMES ======'
    for inc in incomes
      if inc.receiptDate._f
        # Parse the date. It's a former moment.js object made plain by Mongo, but we can rebuild it.
        receiptDate = moment(inc.receiptDate._i, inc.receiptDate._f).toDate()

        console.log "#{inc.description} (#{inc._id}) ... #{inc.receiptDate} -> #{receiptDate}"
        Incomes.update inc._id, {
          $set: {
            receiptDate: receiptDate
          }
        }

    console.log '====== EXPENSES ======'
    for exp in expenses
      if exp.dueDate._f
        # Parse the date. It's in m/dd/yyyy or m/dd/yyyy format.
        dueDate = moment(exp.dueDate._i, exp.dueDate._f).toDate()

        console.log "#{exp.description} (#{exp._id}) ... #{exp.dueDate} -> #{dueDate}"

        Expenses.update exp._id, {
          $set: {
            dueDate: dueDate
          }
        }

    Migrations.insert({name: "20130630_iso_dates_2"})
