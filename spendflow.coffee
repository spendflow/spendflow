_self = @

startSubscriptions = ->
  _self._accountsSub = Meteor.subscribe 'spendflowAccounts', getCurrentProfile()
  _self._sessionsSub = Meteor.subscribe 'spendflowSessions', getCurrentProfile()

startSubscriptions() if Meteor.isClient # Start subscriptions globally

Router.configure {
  autoRender: false
  notFoundTemplate: 'notFound'
  loadingTemplate: 'loading'
}

checkLoggedIn = ->
  if not Meteor.user() and not Meteor.loggingIn()
    @render('public')
    @stop()

  if Meteor.loggingIn() and not (__fast_render_config?.subscriptions?.currentUser and Meteor.user())
    @render(@loadingTemplate)
    @stop()

waitForProfiles = ->
  _self.profilesSubscription = @subscribe('spendflowProfiles')
  _self.profilesSubscription.wait();

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
  Router.before checkLoggedIn
  Router.before waitForProfiles
  Router.before hasProfile, { except: ['profiles'] }
  Router.before applyProfile

Router.map ->
  @route 'index', {
    path: '/'
    fastRender: true
  }

  @route 'profiles', {
    fastRender: true
  }

  @route 'dashboard', {
    path: '/:profileId/dashboard',
    fastRender: true
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
        financeSession = FinanceSessions.findOne @params._id, { reactive: false }
        if financeSession
          financeSession.startDate = formatDate financeSession.startDate
          return financeSession;
        return null;
  }

  # TODO: Convert rest of routes to use FastRender
  @route 'income', {
    path: '/:profileId/income'
  }

  @route 'expenses', {
    path: '/:profileId/expenses'
  }

  @route 'payments', {
    path: '/:profileId/payments'
  }

  @route 'accounts', {
    path: '/:profileId/accounts'
    fastRender: true
    waitOn: ->
      if @params?['profileId']
        profileId = resolveProfileId @params
        _self._accountsSub = Meteor.subscribe 'spendflowAccounts', profileId
      return _self._accountsSub
  }

  @route 'envelopes', {
    path: '/:profileId/envelopes'
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
#    @subscribe 'currentUser'
#    @subscribe 'userData'
#    @subscribe 'systemUsers'
    @subscribe 'spendflowProfiles'
    @subscribe "meteor.loginServiceConfiguration"
