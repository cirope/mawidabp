jQuery(function ($) {
  $(document).on('change', 'select[data-plans-with-prices]', function () {
    var $select  = $(this)
    var value    = $select.val()
    var newPrice = $select.data('plansWithPrices')[value]

    $('.monthly-price').html(newPrice).effect('highlight')
  })
})
