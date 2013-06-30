Meteor.startup ->
  if not Migrations.findOne({name: "20130630_iso_dates"})
    console.log "Running migration: 20130630_iso_dates"

    # Get all income and expense dates
    incomes = Incomes.find({}, { fields: { receiptDate: 1, description: 1 } }).fetch()
    expenses = Expenses.find({}, { fields: { dueDate: 1, description: 1 } }).fetch()

    console.log '====== INCOMES ======'
    for inc in incomes
      # Parse the date. It's in m/dd/yyyy or m/dd/yyyy format.
      receiptDate = moment(inc.receiptDate, "M-DD-YYYY")

      receiptDateLog = receiptDate.format()
      console.log "#{inc.description} (#{inc._id}) ... #{inc.receiptDate} -> #{receiptDateLog}"
      Incomes.update inc._id, {
        $set: {
          receiptDate: receiptDate
        }
      }

    console.log '====== EXPENSES ======'
    for exp in expenses
      # Parse the date. It's in m/dd/yyyy or m/dd/yyyy format.
      dueDate = moment(exp.dueDate, "M-DD-YYYY")

      dueDateLog = dueDate.format()
      console.log "#{exp.description} (#{exp._id}) ... #{exp.dueDate} -> #{dueDateLog}"
      Expenses.update exp._id, {
        $set: {
          dueDate: dueDate
        }
      }

    Migrations.insert({name: "20130630_iso_dates"})
