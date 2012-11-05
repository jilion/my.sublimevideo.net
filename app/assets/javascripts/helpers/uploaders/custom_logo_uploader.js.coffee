#= require helpers/uploader

class MySublimeVideo.Helpers.Uploaders.CustomLogoUploader extends MySublimeVideo.Helpers.Uploader
  constructor: (@options = {}) ->
    _.defaults(@options, { title: 'Custom logo', extensions: 'png' })

    super @options

    @uploader.bind 'FileUploaded', (up, file, response) =>
      eval(response.response)
      $('#kit_setting-logo-image_url').change()
