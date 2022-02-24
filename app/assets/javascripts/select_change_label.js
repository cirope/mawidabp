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

    if ((origination_date != null) && (risk != '') && (values_states_change_label.includes(parseInt(state)))){
      var days_to_add    = (element.data('daysToAdd'))[parseInt(risk)]
      var suggested_date = new Date()

      suggested_date.setDate(origination_date.getDate() + days_to_add)

      var text = $labelTarget.text().concat(element.data('suffix')).concat(formatDate(suggested_date))
    } else {
      var text = $labelTarget.text().split(element.data('suffix'))[0]
    }

    $($labelTarget).text(text)
  }

  function formatDate(date){
    let day = date.getDate()
    let month = date.getMonth() + 1
    let year = date.getFullYear()

    if(month < 10){
      return day + '/0' + month + '/' + year
    } else {
      return day + '/' + month + '/' + year
    }
  }
})
