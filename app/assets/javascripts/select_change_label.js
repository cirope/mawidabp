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
    var $labelTarget               = $('label[for="' + element.data('targetInputWithLabel').replace('#', '') + '"]')
    var origination_date           = $(element.data('targetInputWithOriginationDate')).datepicker().datepicker('getDate')
    var risk                       = $(element.data('targetInputWithRisk')).val()
    var state                      = $(element.data('targetInputWithState')).val()
    var values_states_change_label = element.data('targetValuesStatesChangeLabel')
    var text                       = $labelTarget.text().split(element.data('suffix'))[0]

    if ((origination_date != null) && (risk != '') && (values_states_change_label.includes(parseInt(state)))) {
      var days_to_add = (element.data('daysToAdd'))[parseInt(risk)]

      origination_date.setDate(origination_date.getDate() + days_to_add)

      var text = text.concat(element.data('suffix')).concat(formatDate(origination_date))
    }

    $($labelTarget).text(text)
  }

  function formatDate(date) {
    let day   = String(date.getDate()).padStart(2,'0')
    let month = String(date.getMonth() + 1).padStart(2,'0')
    let year  = date.getFullYear()

    return day + '/' + month + '/' + year
  }
})
