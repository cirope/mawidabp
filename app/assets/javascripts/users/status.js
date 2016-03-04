jQuery(function () {
  $('[data-graph]').each(function (i, e) {
    var element = $(e).attr('id')
    var data    = $(e).data('weaknesses')

    new Chartist.Pie('#' + element, data, {
      chartPadding: 30,
      labelOffset: 85,
      labelDirection: 'explode'
    })
  })
})
