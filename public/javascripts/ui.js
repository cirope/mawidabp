jQuery(function() {
  var MAX_TEXT_AREA_HEIGHT = 400;

  var UIManipulation = {
    changeHeight: function(element, height) {
      element.effect('size', { to: { height: height } }, 300);
    },
    restoreHeight: function() {
      var originalHeight = $(this).data('original-height');

      if(originalHeight) {
        UIManipulation.changeHeight($(this), originalHeight);
      }

      $(this).unbind('blur', UIManipulation.restoreHeight);
    },
    fitToContent: function(element) {
      var adjustedHeight = element.height();

      if(MAX_TEXT_AREA_HEIGHT > adjustedHeight) {
        adjustedHeight = Math.max(element.scrollHeight, adjustedHeight);
        adjustedHeight = Math.min(MAX_TEXT_AREA_HEIGHT, adjustedHeight);

        if(adjustedHeight > element.height()) {
          if(!element.data('original-height')) {
            element.data('original-height', element.height());
          }

          element.blur(UIManipulation.restoreHeight);

          UIManipulation.changeHeight(element, adjustedHeight);
        }
      }
    }
  };

  $('textarea').live('keyup', function() {
    UIManipulation.fitToContent($(this));
  });

  $('textarea').live('click', function() {
    UIManipulation.fitToContent($(this));
  });
});