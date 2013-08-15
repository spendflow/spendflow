Meteor.publish "userData", ->
  return Meteor.users.find({ _id: this.userId }, {
    fields: {
      'createdAt': 1
    }
  })
