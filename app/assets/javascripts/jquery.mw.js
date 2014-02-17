jQuery(function($) {
  var methods = {
    downForIdFromName: function() {
      var id;
      var name = $(this).find('[name$="[id]"]:first').attr('name');

      if(name.match(/.*\[(\d+)\]/)) {
        id = name.match(/.*\[(\d+)\]/)[1];
      }

      return id;
    },
    resetToOriginalText: function() {
      var originalText = $(this).data('mwOriginalText');

      if(originalText) {$(this).html(originalText);}
    },
    toggleContent: function(originalText, alternateText) {
      $(this).data('mwOriginalText', originalText);
      $(this).data('mwAlternateText', alternateText);

      $(this).html(
        $(this).html() == originalText ? alternateText : originalText
      );
    }
  };

  $.fn.mw = function(method) {
    if (methods[method]) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' +  method + ' does not exist on jQuery.mw');

      return false;
    }
  };
});
