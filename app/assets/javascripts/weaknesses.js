$(document).on('change', '[data-weakness-state-changed-url]', function () {
  $state = $(this)
  state  = $state.val()
  url    = $state.data('weaknessStateChangedUrl')

  if (state) {
    $.ajax({
      url: url,
      dataType: 'script',
      data: { state: state }
    })
  }
})
