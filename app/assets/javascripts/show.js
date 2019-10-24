$(document).on('click', '[data-show]', function (event) {
  event.preventDefault()

  var $handle     = $(this)
  var containerId = $handle.data('show')
  var $target     = $('[data-container-id="' + containerId + '"]')
  var $altHandle  = $handle.closest('.media-object').siblings('.media-object[hidden]')

  $target.closest('[data-nested]').removeAttr('hidden')
  $target.removeAttr('hidden')

  $handle.closest('.media-object').attr('hidden', true)
  $altHandle.removeAttr('hidden')
})
