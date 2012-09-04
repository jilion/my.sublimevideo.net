class MySublimeVideo.Helpers.FeedbackForm
  constructor: ->
    if (@cancelAccountCheckbox = $('#cancel_account')).exists()
      @feedbackForm         = $('#new_feedback')
      @feedbackSubmit       = $('#feedback_submit')
      @initialFormAction    = @feedbackForm.attr('action')
      @initialSubmitText    = @feedbackSubmit.val()
      @confirmPasswordBox   = $('#cancel_account_confirm_password')
      @currentPasswordField = $('#user_current_password')

      this.setupObserver()

  setupObserver: ->
    @cancelAccountCheckbox.on 'click', =>
      if @cancelAccountCheckbox.attr('checked')?
        @confirmPasswordBox.show()
        @currentPasswordField.attr('required', 'required')
        @feedbackForm.attr('action', '/account/cancel')
        @feedbackSubmit.val('Cancel my account')
      else
        @confirmPasswordBox.hide()
        @currentPasswordField.removeAttr('required')
        @feedbackForm.attr('action', @initialFormAction)
        @feedbackSubmit.val(@initialSubmitText)
