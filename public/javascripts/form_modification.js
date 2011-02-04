Event.observe(window, 'load', function() {
  document.on('change', 'form', function(event, element) {
    if(!element.hasClassName('no_observe_changes')) {
      State.unsavedData = true;
    }
  });
});

// Verifica antes de cerrar la ventana que los datos no hayan cambiado
window.onbeforeunload = function () {
  if (State.unsavedData) {
    $$('form').each(function(form) {
      Form.getElements(form).each(function(e) {
        if(e.retrieve('reset_value')) { e.setValue(e.retrieve('reset_value')); }
      });
    });

    return State.unsavedDataWarning;
  } else {
    return undefined;
  }
}.bind(this);