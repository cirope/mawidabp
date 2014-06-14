jQuery ->
  $('[data-graph]').each (i, e) ->
    Morris.Donut
      element:   $(e).attr('id')
      data:      $(e).data('weaknesses')
      colors:    ['#40ff00', '#0040ff', '#ff0', '#fe2e2e', '#f0f', '#2efef7', '#424242', '#5882fa']
      formatter: (x) -> "#{x} (#{(x / $(e).data('total') * 100).toFixed(2)}%)"
