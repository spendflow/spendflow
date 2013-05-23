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
