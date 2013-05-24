Template.newAccountForm.events {
  'click .add-account': (event) ->
    # TODO: Better validation
    event.preventDefault();
    # TODO: Convert to use valByName wrapper function
    accountType = $('[name="type"]').val()
    accountName = $('[name="name"]').val()
    accountBalance = if $('[name="balance"]').val().toString() isnt "" then $('[name="balance"]').val() else undefined

    if not accountType or not accountName or (accountType is "payFrom" and (not accountInitialBalance or accountInitialBalance.toString() is ""))
      showNavError "Please select an account type and give it a name. If it's a Pay From account, enter an initial balance, even if that is 0."
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
          showNavSuccess "New account added."
        else
          showNavError "There was a problem adding the new account. Please try again. If the problem persists, contact us."
          console.log error
}

Template.accountList.virtualAccounts = ->
  VirtualAccounts.find().fetch()

Template.accountList.editingAccount = ->
  account = VirtualAccounts.findOne(Session.get 'editingAccount') if Session.get 'editingAccount'
  account

Template.account.events {
  'click .edit-account': (event) ->
    Session.set 'editingAccount', recordIdFromRow event
}
