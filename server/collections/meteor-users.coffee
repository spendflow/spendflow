Meteor.publish "userData", ->
  return Meteor.users.find({ _id: this.userId }, {
    fields: {
      'createdAt': 1
    }
  })

Meteor.publish 'currentUser', ->
  if @userId
    return Meteor.users.find { _id: @userId }, { fields: { profile: 1, username: 1, emails: 1 } }
  return null;

#Meteor.publish(null, function() {
#  if (this.userId) {
#    return Meteor.users.find(
#      {_id: this.userId},
#      {fields: {profile: 1, username: 1, emails: 1}});
#  } else {
#    return null;
#  }
#}
