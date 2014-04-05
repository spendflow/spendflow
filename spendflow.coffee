_self = @

# Initialize subscription variables
@profilesSubscription = null
@_accountsSub = null
@_envelopesSub = null
@_incomesSub = null
@_expensesSub = null
@_paymentsSub = null
@_sessionsSub = null

startSubscriptions = ->
  # TODO: Optimize these only to subscribe to the ones needed for the current page
  # e.g. taking filters, etc. into account
  _self.profilesSubscription = Meteor.subscribe('spendflowProfiles')
  currentProfile = getCurrentProfile()
  console.log "Profile: #{currentProfile}"
  _self._accountsSub = Meteor.subscribe 'spendflowAccounts', currentProfile
  _self._envelopesSub = Meteor.subscribe 'spendflowEnvelopes', currentProfile
  _self._incomesSub = Meteor.subscribe 'spendflowIncomes', currentProfile
  _self._expensesSub = Meteor.subscribe 'spendflowExpenses', currentProfile
  _self._paymentsSub = Meteor.subscribe 'spendflowPayments', currentProfile
  _self._sessionsSub = Meteor.subscribe 'spendflowSessions', currentProfile

Deps.autorun ->
  startSubscriptions() if Meteor.isClient # Start subscriptions globally

Router.configure {
  notFoundTemplate: 'notFound'
  layoutTemplate: 'spendflowMaster'
  loadingTemplate: 'loading'
  waitOn: ->
    return _self.profilesSubscription
}

checkLoggedIn = (pause) ->
  if not Meteor.user() and not Meteor.loggingIn()
    @render('public')
    pause()

#  if Meteor.loggingIn() and not (__fast_render_config?.subscriptions?.currentUser and Meteor.user())
#    thisLoadingTemplate = @lookupProperty 'loadingTemplate'
#    @render(thisLoadingTemplate)
#    pause()

hasProfile = ->
  if @ready() and Meteor.user() and not Profiles.findOne()
    Router.go('profiles')

@applyProfile = ->
  if @ready() and Meteor.user() and @params?.profileId
    # Profile exists?
    profile = Profiles.findOne @params.profileId

    if _.isUndefined(profile) or not profile
      Router.go 'index'
      return;

    Session.set "currentProfile", @params.profileId

if Meteor.isClient
  Router.onBeforeAction checkLoggedIn
  Router.onBeforeAction hasProfile, { except: ['profiles'] }
  Router.onBeforeAction applyProfile
#  Router.onBeforeAction 'loading'
  Router.onBeforeAction 'dataNotFound'

Router.map ->
  @route 'index', {
    path: '/'
    fastRender: true
    data: -> {}
  }

  @route 'profiles', {
    fastRender: true
    data: -> {}
  }

  @route 'dashboard', {
    path: '/:profileId/dashboard',
    # TODO: Narrow subscriptions enough for this to be practical, e.g. to envelope payments
    # and connected income/expenses
#    fastRender: true
#    waitOn: ->
#      return startSubscriptions();
    data: -> {}
  }

  @route 'sessions', {
    path: '/:profileId/sessions'
    template: 'financeSessions',
    fastRender: true
    waitOn: ->
      if Meteor.isServer
        profileId = resolveProfileId @params
        _self._sessionsSub = Meteor.subscribe 'spendflowSessions', profileId
      return _self._sessionsSub
    data: -> {}
  }
  @route 'editSession', {
    path: '/:profileId/sessions/:_id/edit'
    fastRender: true
    waitOn: ->
      if Meteor.isServer
        if @params?['_id'] and @params?['profileId']
          # We only need the one session's data to render
          return [
            Meteor.subscribe('spendflowSession', @params['_id'], @params['profileId'])
          ]
      if Meteor.isClient
        # Just wait on all sessions
        return _self._sessionsSub
    data: ->
      if @params._id and @params.profileId
        # TODO: Sometimes the below overreacts. Try to make it not-too-reactive so that edits in progress aren't lost.
        financeSession = FinanceSessions.findOne @params._id
        if financeSession
          financeSession.startDate = formatDate financeSession.startDate
          return financeSession;
        return null;
  }

  # TODO: Convert rest of routes to use FastRender
  @route 'income', {
    path: '/:profileId/income'
    # fastRender: true
    waitOn: ->
      return _self._incomesSub
    data: -> {}
  }

  @route 'expenses', {
    path: '/:profileId/expenses'
    # fastRender: true
    waitOn: ->
      return _self._expensesSub
    data: -> {}
  }

  @route 'payments', {
    path: '/:profileId/payments'
    # fastRender: true
    waitOn: ->
      return _self._paymentsSub
    data: -> {}
  }

  @route 'accounts', {
    path: '/:profileId/accounts'
    fastRender: true
    waitOn: ->
      if Meteor.isServer
        if @params?['profileId']
          profileId = resolveProfileId @params
          _self._accountsSub = Meteor.subscribe 'spendflowAccounts', profileId
      return _self._accountsSub
    data: -> {}
  }

  @route 'envelopes', {
    path: '/:profileId/envelopes'
    waitOn: ->
      if Meteor.isServer
        if @params?['profileId']
          profileId = resolveProfileId @params
          _self._envelopesSub = Meteor.subscribe 'spendflowEnvelopes', profileId
      return _self._envelopesSub
    data: -> {}
  }

  @route 'expectations', {
    path: '/:profileId/expectations'
    fastRender: true
    data: -> {}
  }

@resolveProfileId = (params) ->
  profileId = undefined
  if Meteor.isServer and not _.isUndefined(params['profileId'])
    profileId = params['profileId']
  if Meteor.isClient
    profileId = getCurrentProfile()
  profileId

if Meteor.isServer
  FastRender.onAllRoutes (urlPath) ->
    @subscribe 'spendflowProfiles'
