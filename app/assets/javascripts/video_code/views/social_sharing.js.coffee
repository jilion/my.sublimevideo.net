class MSVVideoCode.Views.SocialSharing extends Backbone.View
  template: JST['video_code/templates/social_sharing']

  events:
    'change .kit_setting': 'updateSettings'
    'click input#social_sharing_image_url': 'updateSettings'

  initialize: ->
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)

    _.bindAll this, 'render'
    MSVVideoCode.kits.bind 'change', this.render

    this.render()

  #
  # EVENTS
  #
  updateSettings: (event) ->
    $inputField = $(event.target)
    MSVVideoCode.video.updateSetting($inputField.data('addon'), $inputField.data('setting'), $inputField.val())

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#social_sharing_settings_fields').html this.template
      video: MSVVideoCode.video
    $(@el).show()

    this
