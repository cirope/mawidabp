$(document).ajaxStart(function () {
  $('.loading-caption').removeAttr('hidden')
}).ajaxStop(function () {
  $('.loading-caption').attr('hidden', true)
})
