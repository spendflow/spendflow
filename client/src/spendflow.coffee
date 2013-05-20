Meteor.Router.add({
  '/': 'index'
})

Meteor.Router.filters({
  checkLoggedIn: (page) =>
    if Meteor.loggingIn()
      return 'loading'
    else if Meteor.user()
      return page
    else
      return 'public'
})

Meteor.Router.filter('checkLoggedIn')
