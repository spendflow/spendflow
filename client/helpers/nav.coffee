# TODO: Make this use info in meteor-router, if possible
spendflowRoutes = [
  'index'
  'dashboard'
  'financeSessions'
  'accounts'
  'envelopes'
  'income'
  'expenses'
  'payments'
  'profiles'
]

spendflowRoutes.forEach (route) ->
  Template.nav["#{route}Active"] = ->
    # TODO: Needs refactoring if I change paths, but it's fine for now
    if Meteor.Router.page() is route
      return "active"
    else
      return ""

Template.nav.events {
  'click .switch-profile': (event) ->
    $elem = $(event.target)
    newProfileId = $elem.attr('id')

    # Ensure it exists
    profile = Profiles.findOne(newProfileId)

    if profile
      Session.set('currentProfile', newProfileId)

      currentPage = Meteor.Router.page()

      if Meteor.Router["#{currentPage}Url"]
        # Route to same page we're on but with new profile
        Meteor.Router.to(currentPage, newProfileId)
      else
        # Just gets ignored otherwise
        Meteor.Router.to("dashboard", newProfileId)
}
