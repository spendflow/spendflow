Deps.autorun ->
  currentUser = Meteor.user()
  if currentUser
    identity = {}
    identity.email = currentUser.emails[0].address if currentUser.emails.length
    identity.name = if currentUser.profile.name then currentUser.profile.name else currentUser.username
    identity.username = currentUser.username if currentUser.username
    identity.created = moment(currentUser.createdAt).toDate() if currentUser.createdAt

    SpendflowStats.identify Meteor.userId(), identity

    # Set the profileId if it isn't set
    if not Session.get "currentProfile" then Session.set "currentProfile", getLatestProfileId()


Deps.autorun ->
  currentProfile = Session.get "currentProfile"

  if (currentProfile) then Meteor.users.update(Meteor.userId(), { $set: { 'profile.latestProfile': currentProfile } })

@applyProfile = (template, profileId = null) ->
  if not profileId
    # Return a callback that takes the profileId and either shows the index page (if it's invalid) or the page we wanted
    return (profileId) ->
      applyProfileCheck template, profileId
  else
    # Call it directly
    applyProfileCheck template, profileId

@applyProfileCheck = (template, profileId) ->
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
        return page;
      else
        return 'profiles';
    page
})

Meteor.Router.filter('checkLoggedIn')
Meteor.Router.filter('hasProfile')

Meteor.Router.add({
  '/': 'index'
  '/:profileId/dashboard': {
    as: 'dashboard',
    to: applyProfile('dashboard')
  }
  '/:profileId/sessions': {
    as: 'sessions',
    to: applyProfile('financeSessions')
  }
  '/:profileId/sessions/:sessionId/edit': {
    as: 'editSession',
    to: (profileId, sessionId) ->
      sessionsReady = Session.equals("financeSessionsReady", true)
      if (sessionsReady)
        financeSession = FinanceSessions.findOne(sessionId, { reactive: false })
        if financeSession
          Session.set "currentFinanceSession", financeSession
          return applyProfile('editSession', profileId);
      return applyProfile("notFound", profileId)
  }
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
  # showAlert(message, $(successAlertSelector))
  showAlert(message, "success")

@showNavError = (message) ->
  # Show errors indefinitely
#  showAlert(message, $(errorAlertSelector), true, null)
  showAlert(message, "error")

# Race condition? Removed for now, opened issue
#Meteor.startup ->
#  # Send metadata to stuff
#  analytics.initialize {
#    'Errorception': {
#      meta: true
#    }
#  }
