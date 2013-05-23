# TODO: Make this use info in meteor-router
spendflowRoutes = [
  'accounts'
  'envelopes'
  'income'
  'expenses'
  'payments'
  'tasks'
]

spendflowRoutes.forEach (route) ->
  Template.nav["#{route}Active"] = ->
    # TODO: Needs refactoring if I change paths, but it's fine for now
    if Meteor.Router.page() is route
      return "active"
    else
      return ""
