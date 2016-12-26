jQuery(function ($) {
  var controllerSelector = '[data-controller="users"], [data-controller="registrations"]'

  if ($(controllerSelector).length) {
    $(document).on('click', '[data-clear-user-manager]', function (event) {
      event.preventDefault()

      $('#user_manager, #user_manager_id').val('')
    })

    $(document).on('change', '[data-update-role]', function () {
      var $element = $(this)
      var role     = $($element.data('updateRole'))

      if($element.val()) {
        Helper.showLoading($element)

        $.get($element.data('rolesUrl'), {
          id: $element.val(),
          format: 'json'
        }, function (data) {
          HTMLUtil.updateOptions(role, HTMLUtil.optionsFromArray(data))
        }).complete(function () {
          role.val('')
          Helper.hideLoading($element)
        })
      } else {
        role.html('').attr('disabled', true)
      }
    })
  }
})
