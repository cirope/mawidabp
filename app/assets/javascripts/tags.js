jQuery(function ($) {
  $(document).on('click', '[data-icon]', function (event) {
    event.preventDefault()

    var icon = $(this).data('icon')

    $('[data-icon]').closest('li').removeClass('active')
    $('[data-icon="' + icon + '"]').closest('li').addClass('active')

    $('[name$="[icon]"]').val(icon)
  })
})
