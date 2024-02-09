jQuery(function ($) {
  $(document).on('click', '[data-recode-tasks]', function (event) {
    var code = 0

    event.preventDefault()
    event.stopPropagation()

    $('[data-task-code]').each(function (i, element) {
      $(element).val((++code).toPaddedString(2))
    })
  })

  $(document).on('dynamic-item:added', '[data-association="tasks"]', function () {
    var nextCode = 0

    $('[data-task-code]').each(function (i, element) {
      var code = +$(element).val()

      if (! code)
        $(element).val((++nextCode).toPaddedString(2))

      if (code > nextCode)
        nextCode = code
    })
  })
})
