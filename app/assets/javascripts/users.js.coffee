jQuery ->
  colors = ['#40FF00', '#0040FF', '#FFFF00', '#FE2E2E', '#FF00FF', '#2EFEF7', '#424242', '#5882FA']

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

