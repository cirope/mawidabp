$(document).on('change', '[data-weakness-state-changed-url]', function () {
  var $state = $(this)
  var state  = $state.val()
  var url    = $state.data('weaknessStateChangedUrl')

  if (state) {
    $.ajax({
      url: url,
      dataType: 'script',
      data: { state: state }
    })
  }
})

$(document).on('change', '[data-mark-impact-as]', function () {
  var impact = $(this).data('markImpactAs')
  var markOn = $(this).data('markImpactOn')

  if ($(this).val() === markOn)
    $('[id$=_impact_' + impact.toLowerCase() + ']').prop('checked', true)
})
