jQuery ($) ->
  $(document).on 'change', '[data-business-unit-score]', ->
    scores = []
    total  = 0
    score  = $(@).data('businessUnitScore')

    $("[data-business-unit-score=\"#{score}\"]").each (i, e) ->
      scores.push $(e).val() if $(e).val()

    $.each scores, (i, s) -> total += +s

    scoreValue = if scores.length then '' + Math.round(total / scores.length) else ''

    $("[data-score-target=\"#{score}\"]").val(scoreValue).change()
