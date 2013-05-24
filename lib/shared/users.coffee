@getCurrentUserId = (parentContext) ->
  userId = null
  if Meteor.isClient then userId = Meteor.userId()
  if Meteor.isServer and self.userId then userId = parentContext.userId
  userId
