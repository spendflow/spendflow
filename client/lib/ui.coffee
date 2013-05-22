@showAlert = (message, element, hideOthers = true) ->
  if hideOthers then $('.alert').hide()
  $(element).html(message).show();
