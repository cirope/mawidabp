jQuery(function ($) {
  $(document).on('change', '[data-time-summary-url]', function () {
    var $userSelect = $(this)
    var userId      = JSON.parse($userSelect.val())
    var urlTemplate = decodeURI($userSelect.data('timeSummaryUrl'))
    var url         = urlTemplate.replace('[USER_ID]', userId)

    window.location = url
  })
})
