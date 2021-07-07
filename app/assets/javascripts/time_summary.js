jQuery(function ($) {
  $(document).on('change', '[data-time-summary-url]', function () {
    var $userSelect = $(this)
    var userId      = $userSelect.val()
    var urlTemplate = decodeURI($userSelect.data('timeSummaryUrl'))

    window.location = urlTemplate.replace('[USER_ID]', userId)
  })

  $(document).on('change', '[data-require]', function (event) {
    $element        = $(event.currentTarget)
    $option         = $element.find('option:selected')
    $require_detail = $option.data('require_detail')

    if ($require_detail) {
      $('#require_detail').removeAttr('hidden')
    } else {
      $('#require_detail').attr('hidden', true)
    }
  })
})
