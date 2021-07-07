jQuery(function ($) {
  $(document).on('change', '[data-time-summary-url]', function () {
    var $userSelect = $(this)
    var userId      = $userSelect.val()
    var urlTemplate = decodeURI($userSelect.data('timeSummaryUrl'))

    window.location = urlTemplate.replace('[USER_ID]', userId)
  })

  $(document).on('change', '[data-time-summary-require]', function () {
    var $element       = $(this)
    var $option        = $element.find('option:selected')
    var requireDetail  = $option.data('require_detail')

    if (!requireDetail) {
      $('[data-show-detail]').addClass('d-none')
    } else {
      $('[data-show-detail]').removeClass('d-none')
    }
  })
})
