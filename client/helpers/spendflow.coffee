@applyProfile = (template) ->
  # Return a callback that takes the profileId and either shows the index page (if it's invalid) or the page we wanted
  return (profileId) ->
    # Profile exists?
    profile = Profiles.findOne profileId

    if not profile
      return 'index'

    Session.set "currentProfile", profileId
    template

Meteor.Router.filters({
  checkLoggedIn: (page) =>
    if Meteor.loggingIn()
      'loading'
    else if Meteor.user()
      page
    else
      'public'

  hasProfile: (page) =>
    if Meteor.user()
      if Profiles.findOne()
        return page
      else
        return 'profiles'
    page
})

Meteor.Router.filter('checkLoggedIn')
Meteor.Router.filter('hasProfile')

Meteor.Router.add({
  '/': 'index'
  '/:profileId/income': {
    as: 'income'
    to: applyProfile('income')
  }
  '/:profileId/expenses': {
    as: 'expenses'
    to: applyProfile('expenses')
  }
  '/:profileId/payments': {
    as: 'payments'
    to: applyProfile('payments')
  }
  '/:profileId/accounts': {
    as: 'accounts'
    to: applyProfile('accounts')
  }
  '/:profileId/envelopes': {
    as: 'envelopes'
    to: applyProfile('envelopes')
  }
  '/profiles': {
    as: 'profiles'
    to: 'profiles'
  }
})

# Define some generally-useful stuff
@successAlertSelector = "#nav-flash-success"
@errorAlertSelector = "#nav-flash-error"

@showNavSuccess = (message) ->
  showAlert(message, $(successAlertSelector))

@showNavError = (message) ->
  showAlert(message, $(errorAlertSelector))

Meteor.startup ->
  # Send metadata to stuff
  analytics.initialize {
    'Errorception': {
      meta: true
    }
  }

Deps.autorun ->
  currentUser = Meteor.user()
  if currentUser
    identity = {}
    identity.email = currentUser.emails[0].address if currentUser.emails.length
    identity.name = if currentUser.profile.name then currentUser.profile.name else currentUser.username
    identity.username = currentUser.username if currentUser.username
    identity.created = moment(currentUser.createdAt).toDate() if currentUser.createdAt

    SpendflowStats.identify Meteor.userId(), identity
