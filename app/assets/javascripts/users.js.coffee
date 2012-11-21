jQuery ->
  colors = ['#585858', '#00FF00', '#0000FF', '#FFFF00', '#FF0000', '#BDBDBD', '#FF00FF', '#2EFEF7']

  Morris.Donut
    element: 'high_risk_weaknesses_graph',
    data: $('#high_risk_weaknesses_graph').data('weaknesses')
    colors: colors
    formatter: (x) -> x + ' (' + (x / $('#high_risk_weaknesses_graph').data('total') * 100).toFixed(2) + '%' + ')'

  Morris.Donut
    element: 'status_weaknesses_graph',
    data: $('#status_weaknesses_graph').data('weaknesses')
    colors: colors
    formatter: (x) -> x + ' (' + (x / $('#status_weaknesses_graph').data('total') * 100).toFixed(2) + '%' + ')'

  Morris.Donut
    element: 'pending_weaknesses_graph',
    data: $('#pending_weaknesses_graph').data('weaknesses')
    colors: colors
    formatter: (x) -> x + ' (' + (x / $('#pending_weaknesses_graph').data('total') * 100).toFixed(2) + '%' + ')'

