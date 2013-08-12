Handlebars.registerHelper "equal", (lvalue, rvalue, options) ->
  throw new Error("Handlebars helper equal needs 2 parameters")  if arguments.length < 3
  unless lvalue is rvalue
    false
  else
    true

Handlebars.registerHelper "multiline", (text) ->
  text = Handlebars.Utils.escapeExpression(text)
  text = text.toString()
  text = text.replace(/(\r\n|\n|\r)/g, "<br>")
  new Handlebars.SafeString(text)

Handlebars.registerHelper "profileId", ->
  getCurrentProfile()

Handlebars.registerHelper "profile", ->
  if getCurrentProfile() then Profiles.findOne getCurrentProfile() else return null;

Handlebars.registerHelper "profiles", ->
  Profiles.find().fetch()
