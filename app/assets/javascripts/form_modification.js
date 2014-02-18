jQuery(function() {
  $('form:not([data-no-observe-changes])').change(function() {
    State.unsavedData = true;
  });

  // Verifica antes de cerrar la ventana que los datos no hayan cambiado
  $(window).bind('beforeunload', function() {
    if (State.unsavedData) {
      $('form').each(function(i, form) {
        $(form).find(':input, :checkbox').each(function(i, e) {
          if($(e).data('resetValue')) { $(e).val($(e).data('resetValue')); }
        });
      });

      return State.unsavedDataWarning;
    } else {
      return undefined;
    }
  });
});
