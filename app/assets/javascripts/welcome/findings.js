/* global Chartist */

jQuery(function () {
  $('[data-graph]').each(function (i, e) {
    var element = $(e).attr('id')
    var data    = $(e).data('findings')
    var options = {
      stackBars: true,
      height: '400px',
      width: '60%',
      axisY: { onlyInteger: true }
    }

    new Chartist.Bar('#' + element, data, options)
  })
})
