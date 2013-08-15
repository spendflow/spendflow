if Meteor.isClient
  Deps.autorun ->
    Meteor.subscribe "userData"
