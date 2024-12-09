$(document).on('change', '[data-mark-impact-as]', function () {
  var impact = $(this).data('markImpactAs')
  var markOn = $(this).data('markImpactOn')

  if ($(this).val() === markOn) {
    if (impact) {
      $('[id$=_impact_' + impact.toLowerCase() + ']').prop('checked', true)
    }

    $('[data-compliance-observations]').removeAttr('hidden')
  } else {
    if (impact) {
      $('[id$=_impact_' + impact.toLowerCase() + ']').prop('checked', false)
    }

    $('[data-compliance-observations]').prop('hidden', true)
    $('[data-compliance-observations-text]').val('')
    $('[data-compliance-maybe-sanction]').val(null)
  }
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
  var id                     = $(this).val()
  var url                    = $(this).data('weaknessTemplateChangedUrl')
  var controlObjectiveItemId = $(this).data('controlObjectiveItemId')

  $('#weakness_weakness_template').prop('disabled', true)
  $('#weakness_weakness_template_from_control_objective').prop('disabled', true)

  $.ajax({
    url: url,
    dataType: 'script',
    data: { id: id, control_objective_item_id: controlObjectiveItemId }
  }).always(function () {
    $('#weakness_weakness_template').prop('disabled', false)
    $('#weakness_weakness_template_from_control_objective').prop('disabled', false)
  })
})

$(document).on('click custom:change', '[data-tag]', function (event) {
  var $element = $(event.currentTarget)
  var tagName  = $element.data('tag')
  var $input   = $('input[name$="[tag_ids][]"][data-name="' + tagName + '"]')

  if ($element.prop('type') === 'checkbox')
    $input.prop('checked', $element.is(':checked'))
})

$(document).on('change', '[data-tag-modifier]', function (event) {
  var $element = $(event.currentTarget)
  var $option  = $element.find('option:selected')
  var tagName  = $option.data('tag')
  var select   = $option.data('select') !== 'no'
  var $input   = $('input[name$="[tag_ids][]"][data-name="' + tagName + '"]')

  $input.prop('checked', select)
})

$(document).on('change', '[data-finding-tagging]', function (event) {
  var $element                            = $(event.currentTarget);
  var findingTaggingValue                 = $element.attr('data-finding-tagging');
  var $findingTaggingDescriptionContainer = $('[data-finding-tagging-description-container="' + findingTaggingValue + '"]');
  var includeDescription;

  if ($element.is('input')) {
    includeDescription = $element.data('item')['include_description?'];
  } else {
    var $option        = $element.find('option:selected');
    includeDescription = $option.data('include-description');
  };

  if (includeDescription) {
    $findingTaggingDescriptionContainer.removeAttr('hidden');
  } else {
    $findingTaggingDescriptionContainer.val('').attr('hidden', true);
  }
});
