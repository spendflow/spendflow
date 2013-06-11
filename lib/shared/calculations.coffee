class @SpendflowMath

# Rounds up cents
SpendflowMath.roundUpCents = (amount) ->
  Math.ceil(amount * 100) / 100