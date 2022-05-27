$(document).on('change', '[data-memo-plan-item-refresh-url]', function () {
  var $period   = $('[name="memo[period_id]"]')
  var $planItem = $('[name="memo[plan_item_id]"]')
  var periodId  = $period.val()
  var url       = $(this).data('memoPlanItemRefreshUrl')

  if (periodId) {
    $period.prop('disabled', true)
    $planItem.prop('disabled', true)

    $.ajax({
      url: url,
      dataType: 'script',
      data: {
        plan_item_id: $planItem.val(),
        period_id: periodId
      }
    }).always(function () {
      $period.prop('disabled', false)
      $planItem.prop('disabled', false)
    })
  }
})
