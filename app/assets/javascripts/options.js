jQuery(function () {
  $(document).on('click', 'a[data-remove-option]', function(event) {
    var $option = $(this).closest('fieldset');

    $option.remove();
  });
})
