window.EffectHelper = {
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
