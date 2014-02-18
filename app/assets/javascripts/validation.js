jQuery(function() {
  $('form').submit(function(event) {
    var hasErrors = false;

    $(':input.required', $(this)).each(function() {
      if($(this).val().match(/^\s*$/)) {
        $(this).closest('.form-group').addClass('has-error');
        hasErrors = true;
      } else {
        $(this).closest('form-group').removeClass('has-error');
      }
    });

    if(hasErrors && State.validationFailedMessage) {
      alert(State.validationFailedMessage);

      event.stopPropagation();
      event.preventDefault();
    } else {
      State.unsavedData = false;
      // Eliminar de los envíos el botón submit y el "snowman"
      $(this).find('input[type="submit"], input[name="utf8"]').attr(
        'disabled', true
      );
    }
  });
});
