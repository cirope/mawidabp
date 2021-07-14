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
    var amountUrl = '/time_summary/estimated_amount/'

    if ($(this).val()){
      $.get(amountUrl, { id: $(this).val() }, function (data) {
        $('[data-time-summary-amounts]').removeClass('d-none')
        $('[data-time-summary-workflow-amount]').text(data['workflow'])
        $('[data-time-summary-time-consumption-amount]').text(data['time_consumption'])
      })
    }else{
      $('[data-time-summary-amounts]').addClass('d-none')
    }
  })
})
