$(document).ajaxStart(function () {
  $('.loading-caption').removeClass('hidden')
}).ajaxStop(function () {
  $('.loading-caption').addClass('hidden')
})
