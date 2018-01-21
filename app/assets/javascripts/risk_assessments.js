jQuery(function ($) {
  $(document).on('autocomplete:update', '[data-complete-business-unit-type]', function () {
    var $input = $(this)
    var target = $input.data('completeBusinessUnitType')
    var data   = $input.data('item')

    $(target).val(data.informal)
  })

  $(document).on('change', '[data-update-risk-item]', function () {
    var $input        = $(this)
    var id            = $input.data('updateRiskItem')
    var $values       = $('[data-update-risk-item="' + id + '"]')
    var values        = $values.map(function () { return $(this).val() }).get()
    var allWithValues = values.reduce(function (a, v) { return a && v }, true)

    if (allWithValues) {
      var risk    = 0
      var maxRisk = 0

      $values.each(function () {
        var $value  = $(this)
        var $weight = $value.closest('fieldset').find('[name$="[weight]"]')
        var value   = +$value.val()
        var weight  = +$weight.val()

        risk    += value * weight
        maxRisk += weight * 5

        if (maxRisk > 0)
          $('[data-risk-item="' + id + '"]').val(Math.round(risk / maxRisk * 100))
      })
    }
  })
})
