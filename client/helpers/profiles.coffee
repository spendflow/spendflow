Template.profileList.rendered = ->
  if not Profiles.findOne()
    showNavSuccess "Create your first profile to get started."

Template.profileList.profiles = ->
  Profiles.find().fetch()

Template.profileList.editingProfile = ->
  profile = Profiles.findOne(Session.get 'editingProfile') if Session.get 'editingProfile'
  profile

Template.profile.thisRowBeingEdited = ->
  Session.equals('editingProfile', this._id)

Template.profile.allowDelete = ->
  ! (Profiles.find().count() is 1)

Template.profile.events {
  'click .edit-profile': (event) ->
    event.preventDefault()
    profileId = recordIdFromRow event
    Session.set 'editingProfile', profileId

  'click .remove-profile': (event) ->
    event.preventDefault()
    profileId = recordIdFromRow event
    profile = Profiles.findOne(profileId)

    alertify.confirm "THIS IS A POTENTIALLY DANGEROUS ACTION! If you have any incomes, expenses, payments, accounts, or envelopes using this profile, you will lose access to them!

      Are you sure you want to remove <em>#{profile.name}</em>?", (event) ->
      if event
        Profiles.remove profileId, (error) ->
          if not error
            showNavSuccess "Profile removed."
          else
            showNavError "I couldn't remove the profile for some reason. Try again, and contact us if the problems persist."
            console.log error
}

Template.newProfileForm.profilesCount = ->
  !! Profiles.find().count()

Template.profileForm.events {
  'click .add-profile': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.add-record-form')

    profileValues = parseProfileForm $context

    Profiles.insert profileValues, (error, result) ->
      if not error
        clearFormFields $context
        showNavSuccess "New profile added."
      else
        showNavError "There was a problem adding the new profile. Please try again. If the problem persists, contact us."
        console.log error

  'click .save-profile': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.edit-record-form')
    profileId = recordIdFromForm event

    profileValues = parseProfileForm $context

    Profiles.update profileId, {
      $set: profileValues
    }, (error, result) ->
      if not error
        clearFormFields $context
        showNavSuccess "Profile updated."
        Session.set 'editingProfile', null
      else
        showNavError "There was a problem updating the profile. Please try again. If the problem persists, contact us."
        console.log error

  'click .cancel-editing': (event) ->
    event.preventDefault();
    Session.set 'editingProfile', null
}

parseProfileForm = ($context) ->
  ifp = new FormProcessor $context

  parsedForm = {
    name: ifp.valByName('name')
  }
  parsedForm
