@showAlert = (message, element, hideOthers = true, removeAfter = 5000) ->
  if hideOthers then $('.alert').hide()
  $(element).html(message).show();
  if +removeAfter > 0
    Meteor.setTimeout(->
      $(element).fadeOut();
    , removeAfter)
