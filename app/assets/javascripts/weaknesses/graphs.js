$(document).on('hidden.bs.tab', '[data-clear]', function () {
  var clear = $(this).data('clear')

  $('input[data-clear="' + clear + '"]').val('').trigger('change')
  $('[data-hide-on="tab-change"]').addClass('hidden')
  $('[data-show-on="tab-change"]').removeClass('hidden')
})
