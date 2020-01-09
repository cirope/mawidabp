jQuery(function ($) {
  $(document).on('click', '[data-icon]', function (event) {
    event.preventDefault()

    var icon = $(this).data('icon')

    $('[data-icon]').closest('.nav-link').removeClass('active')
    $('[data-icon="' + icon + '"]').closest('.nav-link').addClass('active')

    $('[name$="[icon]"]').val(icon)
  })
})
