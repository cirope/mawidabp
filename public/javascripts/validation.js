Event.on(window, 'load', function() {
  document.on('submit', function(event) {
    var hasErrors = false;

    $$('.required').each(function(e) {
      if(e.getValue().blank()) {
        e.addClassName('error_field');
        hasErrors = true;
      } else {
        e.removeClassName('error_field');
      }
    });

    if(hasErrors && State.validationFailedMessage) {
      alert(State.validationFailedMessage);
      event.stop();
    } else {
      State.unsavedData = false;
    }
  });
});