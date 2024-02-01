$(document).ajaxStart(function () {
  $('.loading-caption').removeAttr('hidden')
}).ajaxStop(function () {
  $('.loading-caption').attr('hidden', true)
})

$(document).on('shown.bs.modal', '#modal', function() {
  $(this).find('[autofocus]').focus()
})

$(document).on('hidden.bs.modal', '#modal', function() {
  $('#modal').remove()
})
