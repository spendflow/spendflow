@formatDate = (dateObj) ->
  # TODO: Make this use the user's settings to format the date
  dateObj = moment(dateObj) # Should be a moment, but might not be. This won't hurt.
  dateObj.format 'L'