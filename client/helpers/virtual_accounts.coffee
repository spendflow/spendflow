Template.newAccountForm.events {
  'click .add-account': (event) ->
    # TODO: Better validation
    event.preventDefault();
    accountType = $('[name="type"]').val()
    accountName = $('[name="name"]').val()
    accountBalance = if $('[name="balance"]').val().toString() isnt "" then $('[name="balance"]').val() else undefined

    if not accountType or not accountName or (accountType is "payFrom" and (not accountInitialBalance or accountInitialBalance.toString() is ""))
      showAlert("Please select an account type and give it a name. If it's a Pay From account, enter an initial balance, even if that is 0.", $(errorAlertSelector))
    else
      # Add!!!
      VirtualAccounts.insert {
        owner: Meteor.userId()
        type: accountType
        name: accountName
        balance: accountBalance
      }, (error, result) ->
        if not error
          $('input, select', $('#new-account-form')).val("")
          showAlert("New account added.", $(successAlertSelector))
        else
          showAlert("There was a problem adding the new account. Please try again. If the problem persists, contact us.", $(errorAlertSelector))
          console.log error
}

Template.accountList.virtualAccounts = ->
  VirtualAccounts.find().fetch()
