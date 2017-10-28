$(document).on('change', '[data-review-role]', function () {
  $(this).
    parents('fieldset').
    find('[data-include-signature]').
    prop('checked', $(this).val() !== '-1').
    trigger('change')
})

$(document).on('change', '[data-next-identification-number-url]', function () {
  var prefix = $('[name="review[identification_prefix]"]').val()
  var suffix = $('[name="review[identification_suffix]"]').val()
  var url    = $(this).data('nextIdentificationNumberUrl')

  if (prefix) {
    $.ajax({
      url: url,
      dataType: 'script',
      data: {
        prefix: prefix,
        suffix: suffix
      }
    })
  } else {
    $('[name="review[identification_number]"]').val('')
  }
})
