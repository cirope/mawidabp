jQuery(function ($) {
  $(document).on('change', '#best_practice_obsolete', function (event) {
    $('[type="checkbox"][name$="[obsolete]"]').prop('checked', $(this).prop('checked'))
  })

  $(document).on('change', '[data-process-control]', function (event) {
    var id = $(this).data('processControl')

    console.log('obsoletin', id)

    if (id)
      $('[data-process-control-id="' + id + '"]').prop('checked', $(this).prop('checked'))
  })
})
