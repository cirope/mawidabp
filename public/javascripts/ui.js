var MAX_TEXT_AREA_HEIGHT = 400;

var UIManipulation = {
  changeHeight: function(element, height) {
    new Effect.Morph(element, {
      style: 'height: ' + height + 'px',
      duration: 0.3
    });
  },
  restoreHeight: function(event, element) {
    var originalHeight = element.retrieve('original-height');

    if(originalHeight) {
      UIManipulation.changeHeight(element, originalHeight);
    }

    element.stopObserving('blur', UIManipulation.restoreHeight);
  },
  fitToContent: function(element) {
    var adjustedHeight = element.getLayout().get('height');

    if(MAX_TEXT_AREA_HEIGHT > adjustedHeight) {
      adjustedHeight = Math.max(element.scrollHeight, adjustedHeight);
      adjustedHeight = Math.min(MAX_TEXT_AREA_HEIGHT, adjustedHeight);

      if(adjustedHeight > element.getHeight()) {
        if(!element.retrieve('original-height')) {
          element.store('original-height', element.getLayout().get('height'));
        }
        
        element.on('blur', UIManipulation.restoreHeight);

        UIManipulation.changeHeight(element, adjustedHeight);
      }
    }
  }
};

document.on('keyup', 'textarea', function(event, element) {
  UIManipulation.fitToContent(element);
});

document.on('click', 'textarea', function(event, element) {
  UIManipulation.fitToContent(element);
});