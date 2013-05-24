Template.newEnvelopeForm.virtualAccounts = ->
  virtualAccounts = getVirtualAccounts()

  selectOptions = for virtualAccount in virtualAccounts
    {
      optionValue: virtualAccount._id
      optionText: virtualAccount.name
    }

Template.envelopeList.envelopes = ->
  Envelopes.find().fetch()

Template.envelope.virtualAccount = ->
  VirtualAccounts.findOne(this.virtualAccountId).name

Template.newEnvelopeForm.events {
  'click .add-envelope': (event) ->
    event.preventDefault();

    virtualAccountId = valByName "virtualAccountId"
    rate = valByName "rate"
    enabledByDefault = checkboxStateByName "enabledByDefault"
    active = checkboxStateByName "active"

    if not virtualAccountId or not rate
      showNavError "Please pick an account and enter a rate."
    else
      Envelopes.insert {
        owner: getCurrentUserId()
        virtualAccountId: virtualAccountId
        rate: rate
        enabledByDefault: enabledByDefault
        active: active
      }, (error, result) ->
        if not error
          $('input, select', $('#new-envelope-form')).val("")
          showNavSuccess "New envelope added."
        else
          showNavError "There was a problem adding the new envelope. Please try again. If the problem persists, contact us."
          console.log error
}

Template.envelope.events {
  'click .remove-envelope': (event) ->
    envelopeId = $(event.target).parents('tr').attr("data-target")
    Envelopes.remove envelopeId, (error) ->
      if not error
        showNavSuccess "Envelope removed."
      else
        showNavError "I couldn't remove the envelope for some reason. Try again, and contact us if problems persist."
        console.log error
}
