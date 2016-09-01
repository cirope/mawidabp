$(document).on('click', '[data-show]', function (event) {
  event.preventDefault()

  var $handle     = $(this)
  var containerId = $handle.data('show')
  var $target     = $('[data-container-id="' + containerId + '"]')
  var $altHandle  = $handle.closest('.media-object').siblings('.media-object.hidden')

  $target.closest('.nested').removeClass('hidden')
  $target.removeClass('hidden')

  $handle.closest('.media-object').addClass('hidden')
  $altHandle.removeClass('hidden')
})
