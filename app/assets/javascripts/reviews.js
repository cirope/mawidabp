$(document).on('change', '[data-plan-item-refresh-url]', function () {
  var $period   = $('[name="review[period_id]"]')
  var $prefix   = $('[name="review[identification_prefix]"]')
  var $planItem = $('[name="review[plan_item_id]"]')
  var periodId  = $period.val()
  var url       = $(this).data('planItemRefreshUrl')

  if (periodId) {
    $period.prop('disabled', true)
    $prefix.prop('disabled', true)
    $planItem.prop('disabled', true)

    $.ajax({
      url: url,
      dataType: 'script',
      data: {
        prefix: $prefix.val(),
        plan_item_id: $planItem.val(),
        period_id: periodId
      }
    }).always(function () {
      $period.prop('disabled', false)
      $prefix.prop('disabled', false)
      $planItem.prop('disabled', false)
    })
  }
})

$(document).on('change', '[data-review-role]', function () {
  $(this).
    closest('.review_user_assignment').
    find('[data-include-signature]').
    prop('checked', $(this).val() !== '-1').
    trigger('change')
})

$(document).on('change', '[data-next-identification-number-url]', function () {
  var prefix        = $('[name="review[identification_prefix]"]').val()
  var suffix        = $('[name="review[identification_suffix]"]').val()
  var independentId = $(this).find(':selected').data('usePrefix')
  var url           = $(this).data('nextIdentificationNumberUrl')

  if (prefix) {
    $.ajax({
      url: url,
      dataType: 'script',
      data: {
        prefix:     prefix,
        suffix:     suffix,
        use_prefix: independentId
      }
    })
  } else {
    $('[name="review[identification_number]"]').val('')
  }
})

$(document).on('autocomplete:update', '[data-assignment-type-refresh-url]', function (event, input) {
  var $input     = $(input)
  var $typeInput = $input.closest('.review_user_assignment').find('[name$="[assignment_type]"]')
  var url        = $input.data('assignmentTypeRefreshUrl')
  var user       = $input.data('item')

  if (user && user.id) {
    $typeInput.prop('disabled', true)

    $.ajax({
      url: url,
      dataType: 'script',
      data: {
        user_id: user.id,
        type_input_id: $typeInput.prop('id')
      }
    })
  }
})
