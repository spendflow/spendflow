# Wrapper for getting form field value (<input> and <select>)
# For checkboxes, use @checkboxStateByName
@valByName = (fieldName, $context = undefined) ->
  $("[name=\"#{fieldName}\"]", $context).val();

# Wrapper for getting form checkbox state
@checkboxStateByName = (fieldName, $context = undefined) ->
  $("[name=\"#{fieldName}\"]", $context).is(':checked');

@elementByName = (fieldName, $context = undefined) ->
  $("[name=\"#{fieldName}\"]", $context);

### Wrapper functions for within Template.templateName.events ###

# TODO: Make a common function for both of these, since only one element is different

# Simple wrapper for getting the record ID stored in a <td>'s parent <tr>
@recordIdFromRow = (event) ->
  $(event.target).parents('tr').attr("data-target")

# Simple wrapper for getting the record ID stored in a parent form's data-target
@recordIdFromForm = (event) ->
  $(event.target).parents('form').attr("data-target")
