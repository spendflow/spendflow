###
Profiles
- name
- (future) settings
###

@Profiles = new Meteor.Collection 'profiles'

if Meteor.isClient
  Deps.autorun =>
    Meteor.subscribe 'spendflowProfiles'

# Hooks
@Profiles.before "insert", ensureOwner

@Profiles.before "remove", (userId, selector, previous) ->
  if Profiles.find().count() is 1
    throw new Error("At least one profile is required.");
    false;
