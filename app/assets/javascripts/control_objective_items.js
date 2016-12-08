jQuery(function ($) {
  $(document).on('change', '[data-business-unit-score]', function () {
    var scores = []
    var total  = 0
    var score  = $(this).data('businessUnitScore')

    $('[data-business-unit-score="' + score + '"]').each(function (i, e) {
      if ($(e).val()) scores.push($(e).val())
    })

    $.each(scores, function (i, s) { total += +s })

    var scoreValue = scores.length ? '' + Math.round(total / scores.length) : ''

    $('[data-score-target="' + score + '"]').val(scoreValue).change()
  })
})
