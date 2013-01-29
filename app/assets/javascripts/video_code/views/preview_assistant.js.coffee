class MSVVideoCode.Views.PreviewAssistant extends MSVVideoCode.Views.Preview
  refreshPreview: ->
    super

    options = {}

    if MSVVideoCode.video.get('displayInLightbox')
      $('#lightbox_code_for_textarea').val(@videoTagHelper.generateLightboxCode(href: 'video1'))
      options['id'] = 'video1'
    else
      options['player-kit'] = MSVVideoCode.kits.selected.get('identifier') unless MSVVideoCode.kits.defaultKitSelected()
      $('#lightbox_code_for_textarea').val('')

    $('#video_code_for_textarea').val(@videoTagHelper.generateVideoCode(options))
