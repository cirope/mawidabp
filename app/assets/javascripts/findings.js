jQuery(function ($) {
  $(document).on('change', '[data-repeated-url]', function () {
    var $repeatedSelect = $(this)
    var repeatedId      = $repeatedSelect.val()
    var urlTemplate     = decodeURI($repeatedSelect.data('repeatedUrl'))
    var url             = urlTemplate.replace('[FINDING_ID]', repeatedId)
    var checkFields     = [
      'impact',
      'operational_risk',
      'internal_control_components'
    ]
    var fields          = [
      'title',
      'description',
      'effect',
      'audit_recommendations',
      'risk',
      'priority',
      'answer',
      'audit_comments',
      'compliance'
    ]

    if (repeatedId) {
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

        $.each(checkFields, function (i, field) {
          var values = finding[field] || []

          $('[name$="[' + field + '][]"]').prop('checked', false)

          $.each(values, function (i, value) {
            var $check = $('[name$="[' + field + '][]"][value="' + value + '"]')

            $check.prop('checked', true)
          })

          $('[name$="[' + field + ']"]').val(finding[field])
        })

        $('[name$="[origination_date]"]').prop('readonly', true)
      }).always(function () {
        $repeatedSelect.prop('disabled', false)
      })
    } else {
      $.each(fields, function (i, field) {
        $('[name$="[' + field + ']"]').val('')
      })

      $.each(checkFields, function (i, field) {
        $('[name$="[' + field + '][]"]').prop('checked', false)
      })

      $('[name$="[origination_date]"]').
        datepicker('setDate', new Date).
        prop('readonly', false)
    }
  })
})
