UI.registerHelper "equal", (lvalue, rvalue, options) ->
  throw new Error("Spacebars helper equal needs 2 parameters")  if arguments.length < 3
  unless lvalue is rvalue
    false
  else
    true

UI.registerHelper "multiline", (text) ->
  text = UI._escape(text)
  text = text.toString()
  text = text.replace(/(\r\n|\n|\r)/g, "<br>")
  new Spacebars.SafeString(text)

UI.registerHelper "profileId", ->
  if getCurrentProfile() then return { profileId: getCurrentProfile() } else return null;

UI.registerHelper "profile", ->
  if getCurrentProfile() then Profiles.findOne getCurrentProfile() else return null;

UI.registerHelper "profiles", ->
  Profiles.find().fetch()

UI.registerHelper "setupComplete", ->
  u = Meteor.user()
  if u and u.profile?.hideSetupHelp? isnt true
    return false;
  return true;

UI.registerHelper "maybeEm", ->
  isBlock = @valueOf()

  if isBlock
    Template._maybeEm_wrapInEm
  else
    Template._maybeEm_noop
