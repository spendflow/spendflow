Handlebars.registerHelper "equal", (lvalue, rvalue, options) ->
  throw new Error("Handlebars helper equal needs 2 parameters")  if arguments.length < 3
  unless lvalue is rvalue
    false
  else
    true