Deps.autorun ->
  currentUser = Meteor.user()
  if currentUser
    identity = {}
    identity.email = currentUser.emails[0].address if currentUser.emails?.length
    identity.name = if currentUser.profile?.name then currentUser.profile.name else currentUser.username
    identity.username = currentUser.username if currentUser.username
    identity.created = moment(currentUser.createdAt).toDate() if currentUser.createdAt

    SpendflowStats.identify Meteor.userId(), identity

    # Set the profileId if it isn't set
    if not Session.get "currentProfile" then Session.set "currentProfile", getLatestProfileId()


Deps.autorun ->
  currentProfile = Session.get "currentProfile"

  if (currentProfile) then Meteor.users.update(Meteor.userId(), { $set: { 'profile.latestProfile': currentProfile } })

@extendDocWithProfileId = (doc) ->
  if profileId = getCurrentProfile() then doc?.profileId = profileId
  return doc

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
