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
    var requireDetail  = $option.data('requireDetail')

    if (requireDetail) {
      $('[data-time-summary-detail]').removeClass('d-none')
    } else {
      $('[data-time-summary-detail]').addClass('d-none')
    }
  })

  $(document).on('change', '[data-time-summary-review]', function () {
    var $reviewSelect = $(this)
    var reviewId      = $reviewSelect.val()
    var urlTemplate   = decodeURI($reviewSelect.data('timeSummaryReviewUrl'))
    var url           = urlTemplate.replace('[ID]', reviewId)

    if (reviewId) {
      $.getScript(url)
    } else {
      $('[data-time-summary-amounts]').addClass('d-none')
    }
  })
})
