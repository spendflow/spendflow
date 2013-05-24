@valByName = (fieldName) ->
  $("[name=\"#{fieldName}\"]").val();

@checkboxStateByName = (fieldName) ->
  $("[name=\"#{fieldName}\"]").is(':checked');
