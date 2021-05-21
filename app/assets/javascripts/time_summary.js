jQuery(function ($) {
  $(document).on('change', '[data-time-summary-url]', function () {
    var $userSelect = $(this)
    var userId      = $userSelect.val()
    var urlTemplate = decodeURI($userSelect.data('timeSummaryUrl'))

    window.location = urlTemplate.replace('[USER_ID]', userId)
  })
})
