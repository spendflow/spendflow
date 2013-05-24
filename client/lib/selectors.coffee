# Wrapper for getting form field value (<input> and <select>)
# For checkboxes, use @checkboxStateByName
@valByName = (fieldName) ->
  $("[name=\"#{fieldName}\"]").val();

# Wrapper for getting form checkbox state
@checkboxStateByName = (fieldName) ->
  $("[name=\"#{fieldName}\"]").is(':checked');


### Wrapper functions for within Template.templateName.events ###

# Simple wrapper for getting the record ID stored in a <td>'s parent <tr>
@recordIdFromRow = (event) ->
  $(event.target).parents('tr').attr("data-target")
