@allowViewOwn = {
  insert: (userId, doc) ->
    userId and doc.owner is userId
  update: (userId, doc, fields, modifier) ->
    doc.owner is userId
  remove: (userId, doc) ->
    doc.owner is userId
}
