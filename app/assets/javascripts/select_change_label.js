jQuery(function () {
  $(document).ready(function () {
    $('[data-target-input-with-label]').each(function () {
      changeLabel($(this))
    })
  })

  $(document).on('change', '[data-target-input-with-label]', function () {
    changeLabel($(this))
  })

  function changeLabel(element) {
    var $labelTarget = $('label[for="' + element.data('targetInputWithLabel').replace('#', '') + '"]')

    if (element.find(':selected').val() == element.data('targetValueChangeLabel')) {
      var text = $labelTarget.text().concat(element.data('suffix'))
    } else {
      var text = $labelTarget.text().split(element.data('suffix'))[0]
    }

    $($labelTarget).text(text)
  }
})
