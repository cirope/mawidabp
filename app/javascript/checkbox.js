jQuery(function ($) {
  $(document).on('click', 'input[type="checkbox"][data-readonly="true"]', function (event) {
    event.preventDefault()
    event.stopPropagation()
  })
})
