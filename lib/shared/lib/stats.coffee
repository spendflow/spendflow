###
  This class's function parameters are inspired by Segment.io. It's a light wrapper for it in case I decide to
  switch analytics providers.
###
class @SpendflowStats

analyticsEnabled = false
Meteor.startup =>
  if analytics? and Meteor.isClient then analyticsEnabled = true

SpendflowStats.isEnabled = ->
  analyticsEnabled

SpendflowStats.identify = (userId, traits = {}, context = {}) ->
  if analyticsEnabled
    analytics.identify userId, traits, context

SpendflowStats.track = (action, properties = {}) ->
  # Fail gracefully if unavailable
  if analyticsEnabled
    analytics.track action, properties
