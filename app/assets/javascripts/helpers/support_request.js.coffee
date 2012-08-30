class MySublimeVideo.Helpers.SupportRequest
  constructor: ->
    @currentEnvCheckbox    = jQuery('#current_env')
    @envTextArea           = jQuery('#support_request_env')

    this.setupFileUploadElementsAndObservers()
    this.setupCurrentEnvAndObserver()

  setupFileUploadElementsAndObservers: ->
    @fileUploadBox         = jQuery('#ticket_upload')
    @fileUploadField       = jQuery('#support_request_uploads_0')
    @fileUploadClearButton = jQuery('#cancel_upload')

    @fileUploadClearButton.hide()

    @fileUploadField.on 'change', =>
      @fileUploadClearButton.show() if @fileUploadField.val()?

    @fileUploadClearButton.on 'click', (e) =>
      e.preventDefault()
      this.resetFileUpload()

  resetFileUpload: ->
    @fileUploadBox.html(@fileUploadBox.html())
    this.setupFileUploadElementsAndObservers()

  setupCurrentEnvAndObserver: ->
    # this.setupCurrentEnv()

    @currentEnvCheckbox.on 'click', =>
      this.setupCurrentEnv()

  setupCurrentEnv: ->
    if @currentEnvCheckbox.attr('checked')?
      if (!jQuery.trim(@envTextArea.val()))
        this.setCurrentEnv()
      else if confirm 'This will reset what you already added in the textarea and replace it with your current environment information.'
        this.setCurrentEnv()
      else
        @currentEnvCheckbox.prop("checked", false)
    else
      this.removeCurrentEnv()

  setCurrentEnv: -> 
    @envTextArea.val(navigator.userAgent)
    @envTextArea.attr('readonly', 'readonly')

  removeCurrentEnv: ->
    @envTextArea.val('')
    @envTextArea.removeAttr('readonly')
