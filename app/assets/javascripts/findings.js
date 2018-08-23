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
          $('[name$="[' + field + ']"]').val(finding[field]).trigger('change')
        })

        $.each(['follow_up_date', 'origination_date'], function (i, dateField) {
          var date = new Date(finding[dateField])

          date.setMinutes(new Date().getTimezoneOffset())

          $('[name$="[' + dateField + ']"]').datepicker()
          $('[name$="[' + dateField + ']"]').datepicker('setDate', date)
        })

        $.each(checkFields, function (i, field) {
          var values = finding[field] || []

          $('[name$="[' + field + '][]"]').prop('checked', false).trigger('custom:change')

          $.each(values, function (i, value) {
            var $check = $('[name$="[' + field + '][]"][value="' + value + '"]')

            $check.prop('checked', true).trigger('custom:change')
          })

          $('[name$="[' + field + ']"]').val(finding[field])
        })

        $('[name$="[origination_date]"]').prop('readonly', true)
      }).always(function () {
        $repeatedSelect.prop('disabled', false)
      })
    } else {
      $.each(fields, function (i, field) {
        $('[name$="[' + field + ']"]').val('').trigger('change')
      })

      $.each(checkFields, function (i, field) {
        $('[name$="[' + field + '][]"]').prop('checked', false).trigger('custom:change')
      })

      $('input[type="checkbox"][name$="[tag_ids][]"]').prop('checked', false)

      $('[name$="[origination_date]"]').
        datepicker('setDate', new Date).
        prop('readonly', false)
    }
  })

  var disableFollowUpDate = function () {
    var hasVisibleTasks = !!$('.task:visible').length

    $('[name$="[follow_up_date]"]').prop('readonly', hasVisibleTasks)

    if (hasVisibleTasks)
      changeFollowUpDate()
  }

  $(document).on('dynamic-item:added', '[data-association="tasks"]', disableFollowUpDate)
  $(document).on('dynamic-item:removed dynamic-item:hidden', '[data-dynamic-target=".task"]', disableFollowUpDate)

  var changeFollowUpDate = function () {
    var lang     = $('html').prop('lang')
    var format   = $.datepicker.regional[lang].dateFormat
    var newValue = ''
    var intValue = 0

    $('[data-override-follow-up-date]:visible').each(function (i, e) {
      var val = $(e).val()
      var int = val ? $.datepicker.parseDate(format, val).getTime() : 0

      if (int && int > intValue) {
        intValue = int
        newValue = val
      }
    })

    if (newValue && $('[name$="[follow_up_date]"]').val() != newValue) {
      var $warningElement = $('[data-follow-up-date-changed-warning]')
      var message         = $warningElement.data('followUpDateChangedWarning')

      $('[name$="[follow_up_date]"]').val(newValue)

      alert(message)
    }
  }

  $(document).on('change', '[data-override-follow-up-date]', changeFollowUpDate)
})
