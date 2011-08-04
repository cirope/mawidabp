jQuery(function() {
  var MAX_TEXT_AREA_HEIGHT = 400;

  var UIManipulation = {
    changeHeight: function(element, height) {
      element.stop(true, true).animate({ height: height }, 300);
    },
    restoreHeight: function() {
      var originalHeight = $(this).data('originalHeight');

      if(originalHeight) {
        UIManipulation.changeHeight($(this), parseInt(originalHeight));
      }

      $(this).unbind('blur', UIManipulation.restoreHeight);
    },
    fitToContent: function(element) {
      var adjustedHeight = element.innerHeight();

      if(MAX_TEXT_AREA_HEIGHT > adjustedHeight) {
        adjustedHeight = Math.max(element.get(0).scrollHeight, adjustedHeight);
        adjustedHeight = Math.min(MAX_TEXT_AREA_HEIGHT, adjustedHeight);

        if(adjustedHeight > element.innerHeight()) {
          if(!element.data('originalHeight')) {
            element.data('originalHeight', element.innerHeight());
          }

          element.blur(UIManipulation.restoreHeight);

          UIManipulation.changeHeight(element, adjustedHeight);
        }
      }
    }
  };

  $('textarea').live('keyup click', function() {
    UIManipulation.fitToContent($(this));
  });
});