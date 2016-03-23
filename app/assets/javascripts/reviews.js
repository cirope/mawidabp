$(document).on('change', '[data-review-role]', function () {
  $(this).
    parents('fieldset').
    find('[data-include-signature]').
    prop('checked', $(this).val() !== '-1').
    trigger('change')
})
