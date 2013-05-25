Template.incomeForm.rendered = ->
  $context = $ this.firstNode
  $receiptDate = (elementByName 'receiptDate', $context)
  $receiptDate.datepicker()
