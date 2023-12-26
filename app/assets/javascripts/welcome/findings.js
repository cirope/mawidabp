/* global Chartist */

jQuery(function () {
  $('[data-findings-graph]').each(function (i, e) {
    var element = $(e).attr('id')
    var data    = $(e).data('findings')
    var options = {
      stackBars: true,
      height: '400px',
      axisY: { onlyInteger: true }
    }

    new Chartist.Bar('#' + element, data, options)
  })
})
