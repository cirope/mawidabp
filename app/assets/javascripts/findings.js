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

      $.getScript(url).always(function () {
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

      $('#tasks .task').remove()
      disableFollowUpDate()

      $('[name$="[follow_up_date]"]').datepicker('setDate', null)
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
