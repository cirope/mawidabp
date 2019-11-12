$(document).on('hidden.bs.tab', '[data-clear]', function () {
  var clear = $(this).data('clear')

  $('input[data-clear="' + clear + '"]').val('').trigger('change')
  $('[data-hide-on="tab-change"]').attr('hidden', true)
  $('[data-show-on="tab-change"]').removeAttr('hidden')
})
