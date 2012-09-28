<% if @valid_password %>
  passwordInput = jQuery '<input>'
    type:  'password'
    name:  'user[current_password]'
    value: '<%= params[:password] %>'
    style: 'display:none'

  SublimeVideo.Form.passwordChecker.originForm.prepend(passwordInput)
  SublimeVideo.UI.Utils.closePopup()
  SublimeVideo.Form.passwordChecker.originForm.removeAttr('data-password-protected')
  SublimeVideo.Form.passwordChecker.originForm.submit()
<% else %>
  popup = SublimeVideo.UI.popup.element.find('.popup_wrap')
  left = if popup.position().left > parseInt(popup.css('margin-left')) then popup.position().left else popup.css('margin-left')
  popup.css('margin-left': left).effect('shake', { distance: 15, times: 1 }, 200)
  $('#password_check').val('')
<% end %>
