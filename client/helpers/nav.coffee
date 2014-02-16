# TODO: Make this use info in meteor-router, if possible
spendflowRoutes = [
  'index'
  'dashboard'
  'sessions'
  'accounts'
  'envelopes'
  'income'
  'expenses'
  'payments'
  'profiles'
]

templateRoutes = {

}

spendflowRoutes.forEach (route) ->
  Template.nav["#{route}Active"] = ->
    # TODO: Needs refactoring if I change paths, but it's fine for now
    if Router.current()?.route?.name is route
      return "active"
    else
      return ""

Template.nav.profilesLabel = ->
  if getCurrentProfile() and Router.current()?.route?.name isnt 'profiles'
    (Profiles.findOne getCurrentProfile())?.name or 'Profiles'
  else
    'Profiles'

Template.nav.events {
  'click .switch-profile': (event) ->
    $elem = $(event.target)
    newProfileId = $elem.attr('id')

    # Ensure it exists
    profile = Profiles.findOne(newProfileId)

    if profile
      Session.set('currentProfile', newProfileId)

      currentPage = Router.current()?.route?.name
      # Is this a page that trolls us? De-trollify the route.
      if not _.isUndefined templateRoutes[currentPage]
        currentPage = templateRoutes[currentPage]

      # TODO: Convert
      if Router.current()?.path?
        # Route to same page we're on but with new profile
        routeTarget = currentPage
      else
        # Just gets ignored otherwise
        routeTarget = 'dashboard'

      newParams = _.extend Router.current().params, { profileId: newProfileId };
      Router.go routeTarget, Router.current().params
  'click .hide-setup-help': (event) ->
    event.preventDefault()
    alertify.confirm 'Are you sure you want to turn off the Getting Started help? (You can re-enable it from your <i class="icon-home"></i> Home screen.)', (event) ->
      if (event)
        Meteor.users.update Meteor.userId(), { $set: 'profile.hideSetupHelp' : true }
}
