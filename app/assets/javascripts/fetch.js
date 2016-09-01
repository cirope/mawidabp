$(document).on('click', '[data-fetch]', function (event) {
  event.preventDefault()

  var $handle     = $(this)
  var containerId = $handle.data('fetch')
  var $target     = $('[data-container-id="' + containerId + '"]')
  var url         = $target.data('url')
  var index       = $target.data('index')
  var $altHandle  = $handle.closest('.media-object').siblings('.media-object.hidden')

  $target.closest('.nested.hidden').removeClass('hidden')
  $target.removeClass('hidden')

  $.ajax({
    url:      url,
    dataType: 'script',
    data:     { container: containerId, index: index }
  }).done(function (data) {
    $handle.closest('.media-object').addClass('hidden')
    $altHandle.removeClass('hidden')

    $handle.removeAttr('data-fetch').attr('data-show', containerId)
  })
})
