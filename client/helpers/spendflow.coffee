Meteor.Router.add({
  '/': 'index'
  '/income': 'income'
  '/expenses': 'expenses'
  '/payments': 'payments'
  '/tasks': 'tasks'
  '/accounts': 'accounts'
  '/envelopes': 'envelopes'
})

Meteor.Router.filters({
  checkLoggedIn: (page) =>
    if Meteor.loggingIn()
      return 'loading'
    else if Meteor.user()
      return page
    else
      return 'public'
})

Meteor.Router.filter('checkLoggedIn')

# Define some generally-useful stuff
@successAlertSelector = "#nav-flash-success"
@errorAlertSelector = "#nav-flash-error"

@showNavSuccess = (message) ->
  showAlert(message, $(successAlertSelector))

@showNavError = (message) ->
  showAlert(message, $(errorAlertSelector))

@spendflowPrecision = 2

# TODO: Allow changing accounting.js settings from a UI
accounting.settings.currency.symbol = ""

accounting.settings.currency.precision = 2

accounting.settings.number.precision = 2
