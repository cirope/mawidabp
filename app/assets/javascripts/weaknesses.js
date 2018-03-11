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

$(document).on('change', '#weakness_weakness_template_from_control_objective', function () {
  var selectedId   = $(this).val()
  var selectedText = $('#weakness_weakness_template_from_control_objective option:selected').text()

  $('#weakness_template_id').val(selectedId).change()

  if (selectedId)
    $('#weakness_weakness_template').val(selectedText)
  else
    $('#weakness_weakness_template').val('').change()
})

$(document).on('change', '#weakness_weakness_template', function () {
  $('#weakness_weakness_template_from_control_objective').val('')
})

$(document).on('change', '[data-weakness-template-changed-url]', function () {
  var id  = $(this).val()
  var url = $(this).data('weaknessTemplateChangedUrl')

  $('#weakness_weakness_template').prop('disabled', true)
  $('#weakness_weakness_template_from_control_objective').prop('disabled', true)

  $.ajax({
    url: url,
    dataType: 'script',
    data: { id: id }
  }).always(function () {
    $('#weakness_weakness_template').prop('disabled', false)
    $('#weakness_weakness_template_from_control_objective').prop('disabled', false)
  })
})
