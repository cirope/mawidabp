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

  $(document).on('autocomplete:update', '[data-enable-add-risk-assessment-items]', function () {
    $(this).
      closest('.tab-pane').
      find('[data-add-risk-assessment-items-url]').
      attr('disabled', false)
  })

  $(document).on('click', '[data-add-risk-assessment-items-url]', function (event) {
    var url        = $(this).data('addRiskAssessmentItemsUrl')
    var $container = $(this).closest('.tab-pane')

    event.stopPropagation()
    event.preventDefault()

    var ids = $container.find('[data-apply-id]').map(function () {
      return $(this).val()
    }).get().filter(function (e) { return e })

    if (ids.length) {
      $container.find('[data-disabled-on-apply]').attr('disabled', true)

      $.ajax({
        url:      url,
        dataType: 'script',
        data:     { ids: ids }
      }).done(function () {
        $container.find('[data-disabled-on-apply]').attr('disabled', false)
      })
    }
  })
})
