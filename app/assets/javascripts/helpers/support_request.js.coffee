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
    this.setupCurrentEnv()

    @currentEnvCheckbox.on 'click', =>
      this.setupCurrentEnv()

  setupCurrentEnv: ->
    if @currentEnvCheckbox.attr('checked')?
      this.setCurrentEnv()
    else
      this.removeCurrentEnv()

  setCurrentEnv: ->
    @envTextArea.text(navigator.userAgent)
    @envTextArea.attr('readonly', 'readonly')

  removeCurrentEnv: ->
    @envTextArea.text('')
    @envTextArea.removeAttr('readonly')
