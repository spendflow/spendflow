###
  Common collection-related callbacks. Was created to contain a common before callback for setting up new Mongo documents.
###

# Use with before.insert hooks
@ensureCommonMetadata = (userId, doc) ->
  # We split these up so Profiles can just use ensureOwner directly. It doesn't need a profile.
  ensureOwner(userId, doc)
  ensureProfile(userId, doc)

@ensureOwner = (userId, doc) ->
  userId = getCurrentUserId(this) if not userId
  doc.owner = userId if doc.owner isnt userId
  if not doc.owner
    throw new Error("This record needs an owner to be accepted by the database.")

@ensureProfile = (userId, doc) ->
  userId = getCurrentUserId(this) if not userId
  if Meteor.isClient
    doc.profileId = getCurrentProfile() if not doc.profileId
  if not doc.profileId
    throw new Error("This record needs a profileId to be accepted by the database.")