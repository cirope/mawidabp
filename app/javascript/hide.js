$(document).on('click', '[data-hide]', function (event) {
  event.preventDefault()

  var $handle     = $(this)
  var containerId = $handle.data('hide')
  var $target     = $('[data-container-id="' + containerId + '"]')
  var $altHandle  = $handle.closest('.media-object').siblings('.media-object[hidden]')

  $target.closest('[data-nested]').attr('hidden', true)
  $target.attr('hidden', true)

  $handle.closest('.media-object').attr('hidden', true)
  $altHandle.removeAttr('hidden')
})
