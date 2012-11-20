jQuery ->
  colors = ['#00FF00', '#FF0000', '#0000FF', '#FFFF00', '#2E2E2E', '#FF00FF', '#2EFEF7']

  Morris.Donut
    element: 'high_risk_weaknesses_graph',
    data: $('#high_risk_weaknesses_graph').data('weaknesses')
    colors: colors

  Morris.Donut
    element: 'status_weaknesses_graph',
    data: $('#status_weaknesses_graph').data('weaknesses')
    colors: colors
