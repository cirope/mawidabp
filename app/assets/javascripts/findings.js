jQuery(function ($) {
  $(document).on('change', '[data-repeated-url]', function () {
    var $repeatedSelect = $(this)
    var repeatedId      = $repeatedSelect.val()
    var urlTemplate     = decodeURI($repeatedSelect.data('repeatedUrl'))
    var url             = urlTemplate.replace('[FINDING_ID]', repeatedId)
    var fields          = [
      'title',
      'description',
      'effect',
      'audit_recommendations',
      'risk',
      'priority',
      'answer',
      'audit_comments'
    ]

    if(repeatedId) {
      $repeatedSelect.prop('disabled', true)

      $.getJSON(url, function (finding) {
        $.each(fields, function (i, field) {
          $('[name$="[' + field + ']"]').val(finding[field])
        })

        $.each(['follow_up_date', 'origination_date'], function (i, dateField) {
          var date = new Date(finding[dateField])

          date.setMinutes(new Date().getTimezoneOffset())

          $('[name$="[' + dateField + ']"]').datepicker()
          $('[name$="[' + dateField + ']"]').datepicker('setDate', date)
        })
      }).always(function () {
        $repeatedSelect.prop('disabled', false)
      })
    } else {
      $.each(fields, function (i, field) {
        $('[name$="[' + field + ']"]').val('')
      })
    }
  })
})
