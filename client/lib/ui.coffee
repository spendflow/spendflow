@showAlert = (message, element, hideOthers = true, removeAfter = 5000) ->
#  if hideOthers then $('.alert').hide()
#  $(element).html(message).show();
#  if +removeAfter > 0
#    Meteor.setTimeout(->
#      $(element).fadeOut();
#    , removeAfter)
  if element is "success" then alertify.success message
  if element is "error" then alertify.alert message # So they can copy it or whatever...see how this goes
