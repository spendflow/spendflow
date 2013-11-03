Template.financeSessionList.financeSessions = ->
  financeSessions = FinanceSessions.find({}, { sort: { startDate: -1 } }).fetch()
  financeSessions

Template.financeSessionList.events {
  'click .remove-finance-session': (event) ->
    event.preventDefault()
    financeSessionId = recordIdFromRow event
    financeSession = FinanceSessions.findOne(financeSessionId)
    if financeSession and financeSession.startDate
      startDate = "from " + formatDate(financeSession.startDate)

    alertify.confirm "Are you sure you want to remove this Session#{startDate}?", (event) ->
      if event
        FinanceSessions.remove financeSessionId, (error) ->
          if not error
            showNavSuccess "Session removed."
          else
            showNavError "I couldn't remove the Session for some reason. Try again, and contact us if problems persist."
            console.log error
}

Template.financeSession.startDate = ->
  formatDate @startDate
Template.financeSession.notesTeaser = ->
  return @notes.substring(0, 80)

Template.financeSessionForm.rendered = ->
  $context = $ this.firstNode
  $startDate = (elementByName 'startDate', $context)
  $startDate.datepicker()

  $notes = (elementByName 'notes', $context)
  $notes.autosize();

  # If editing, won't be right size off the bat unless we do this
  $notes.trigger('autosize.resize')

Template.newFinanceSessionForm.events {
  'click .add-finance-session': (event) ->
    # TODO: Better validation
    event.preventDefault();
    $context = $(event.target).parents('.add-record-form')

    startDate = if valByName('startDate') then moment(valByName('startDate'), "MM/DD/YYYY").toDate() else "" # So that validation still works
    notes = valByName 'notes', $context

    if not notes
      showNavError "Enter some notes :)"
    else
      # Add!!!
      # TODO: Reject/hide balance for non-payFrom accounts
      FinanceSessions.insert {
        startDate: startDate
        notes: notes
      }, (error, result) ->
        if not error
          clearFormFields $context
          SpendflowStats.track "Created new Session.", {
            noteLength: notes.length
          }
          Meteor.Router.to('editSession', Session.get("currentProfile"), result)
          showNavSuccess "New Session added."
        else
          showNavError "There was a problem adding the new Session. Please try again. If the problem persists, contact us."
          console.log error
}

Template.editSession.editingFinanceSession = ->
  financeSession = Session.get "currentFinanceSession"
  financeSession.startDate = formatDate financeSession.startDate
  financeSession

Template.financeSessionForm.events {
  'click .save-finance-session': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.edit-record-form')
    financeSessionId = recordIdFromForm event

    financeSession = FinanceSessions.findOne financeSessionId

    startDate = if valByName('startDate') then moment(valByName('startDate'), "MM/DD/YYYY").toDate() else "" # So that validation still works
    notes = valByName 'notes', $context

    if not notes
      showNavError "Enter some notes :)"
    else
      # TODO: MVP / QUIT COPYING THIS! MAKE A COMMON FORM-SAVING PATTERN!
      FinanceSessions.update financeSessionId, {
        $set: {
          startDate: startDate
          notes: notes
        }
      }, (error, result) ->
        if not error
          showNavSuccess "Session updated."
        else
          showNavError "There was a problem updating the Session. Please try again. If the problem persists, contact us."
          console.log error
}
