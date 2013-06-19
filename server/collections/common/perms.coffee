# TODO: Write tests for these
@allowViewOwn = {
  insert: (userId, doc) ->
    userId and doc.owner is userId
  update: (userId, doc, fields, modifier) ->
    # Can't change owner
    notChangingOwner = ! _.contains(fields, 'owner')
    doc.owner is userId and notChangingOwner
  remove: (userId, doc) ->
    doc.owner is userId
}

@denyIfInvalidProfile = {
  insert: (userId, doc) ->
    profile = Profiles.findOne(doc.profileId)
    shouldDeny = ! (doc.profileId and profile and profile.owner is userId)
    shouldDeny
  update: (userId, doc, fieldNames, modifier) ->
    # Can't change a record's profileId. Period.
    if (_.contains(fieldNames, 'profileId'))
      return true
    return false
}
