jQuery(function() {
  $('form').submit(function(event) {
    var hasErrors = false;

    $('.required', $(this)).each(function() {
      if($(this).val().match(/^\s*$/)) {
        $(this).addClass('error_field');
        hasErrors = true;
      } else {
        $(this).removeClass('error_field');
      }
    });

    if(hasErrors && State.validationFailedMessage) {
      alert(State.validationFailedMessage);
      
      event.stopPropagation();
      event.preventDefault();
    } else {
      State.unsavedData = false;
      // Eliminar de los envios el boton submit y el "snowman"
      $(this).find('input[type="submit"], input[name="utf8"]').attr(
        'disabled', true
      );
    }
  });
});