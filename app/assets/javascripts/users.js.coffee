jQuery ($) ->
  if $('[data-controller="users"]').length
    $(document).on 'click', '[data-clear-user-manager]', (event) ->
      $('#user_manager, #user_manager_id').val ''
      event.preventDefault()

    $(document).on 'change', '[data-update-role]', ->
      element = $ this
      role    = $ element.data('updateRole')

      if element.val()
        Helper.showLoading element

        $.get element.data('rolesUrl'), id: element.val(), format: 'json', (data) ->
          HTMLUtil.updateOptions role, HTMLUtil.optionsFromArray(data)
        .complete ->
          role.val ''
          Helper.hideLoading element
      else
        role.html('').attr 'disabled', true
