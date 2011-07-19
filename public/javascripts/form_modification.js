jQuery(function() {
  $('form').change(function() {
    if(!$(this).hasClass('no_observe_changes')) {
      State.unsavedData = true;
    }
  });
});

// Verifica antes de cerrar la ventana que los datos no hayan cambiado
window.onbeforeunload = function () {
  if (State.unsavedData) {
    $('form').each(function() {
      $(':input, :checkbox', $(this)).each(function() {
        if($(this).data('reset-value')) {
          $(this).val($(this).data('reset-value'));
        }
      });
    });

    return State.unsavedDataWarning;
  } else {
    return undefined;
  }
}.bind(this);