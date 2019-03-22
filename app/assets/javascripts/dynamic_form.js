+function () {
  var EffectHelper = {
    hide: function (element, callback) {
      $(element).stop().fadeOut(200, callback)
    },

    remove: function (element, callback) {
      $(element).stop().fadeOut(200, function () {
        setTimeout(function () {
          $(element).remove()
        }, 200)

        if (typeof callback === 'function') callback()
      })
    }
  }

  var DynamicFormEvent = {
    addNestedItem: function ($e) {
      var template    = $e.data('dynamicTemplate')
      var regexp      = new RegExp($e.data('id'), 'g')
      var partial     = DynamicFormHelper.replaceIds(template, regexp)
      var $insertInto = $($e.data('insertInto'))

      if ($insertInto.length)
        $insertInto.append(partial)
      else
        $e.before(partial)

      $e.trigger('dynamic-item:added', $e)
    },

    insertNestedItem: function ($e) {
      var source          = $e.data('dynamicSource')
      var $templateHolder = DynamicFormHelper.findInNearestFieldset($e, source)
      var template        = $templateHolder.data('dynamicTemplate')
      var regexp          = new RegExp($templateHolder.data('id'), 'g')

      $e.closest('fieldset').before(DynamicFormHelper.replaceIds(template, regexp))

      $e.trigger('dynamic-item:added', $e)
    },

    hideItem: function ($e) {
      $e.prev('input[type=hidden].destroy').val('1')

      EffectHelper.hide($e.closest('fieldset'), function () {
        $e.trigger('dynamic-item:hidden', $e)
      })
    },

    removeItem: function ($e) {
      EffectHelper.remove($e.closest('fieldset'), function () {
        $e.trigger('dynamic-item:removed', $e)
      })
    }
  }

  var DynamicFormHelper = {
    newIdCounter: 0,

    replaceIds: function (s, regex) {
      return s.replace(regex, new Date().getTime() + DynamicFormHelper.newIdCounter++)
    },

    findInNearestFieldset: function (element, selector) {
      var $fieldset = $(element).parents('fieldset')
      var result    = $fieldset.find(selector)

      while ($fieldset.length && ! result.length) {
        $fieldset = $fieldset.parents('fieldset')
        result    = $fieldset.find(selector)
      }

      return result.length && result || $(selector)
    }
  }

  jQuery(function ($) {
    var linkSelector = 'a[data-dynamic-form-event]'
    var eventList    = $.map(DynamicFormEvent, function (v, k) { return k })

    $(document).on('click', linkSelector, function (event) {
      if (event.stopped) return

      var eventName = $(this).data('dynamicFormEvent')

      if ($.inArray(eventName, eventList) !== -1) {
        State.unsavedData = true

        DynamicFormEvent[eventName]($(this))

        event.preventDefault()
        event.stopPropagation()
      }
    })

    $(document).on('dynamic-item:added', linkSelector, function (event, element) {
      $(element).prev('fieldset').find(
        '[autofocus]:not([readonly]):enabled:visible:first'
      ).focus()
    })

    $('[name$="[_destroy]"][value=1]').closest('fieldset').hide()
  })
}()
