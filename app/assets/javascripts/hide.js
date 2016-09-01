$(document).on('click', '[data-hide]', function (event) {
  event.preventDefault()

  var $handle     = $(this)
  var containerId = $handle.data('hide')
  var $target     = $('[data-container-id="' + containerId + '"]')
  var $altHandle  = $handle.closest('.media-object').siblings('.media-object.hidden')

  $target.closest('.nested').addClass('hidden')
  $target.addClass('hidden')

  $handle.closest('.media-object').addClass('hidden')
  $altHandle.removeClass('hidden')
})
