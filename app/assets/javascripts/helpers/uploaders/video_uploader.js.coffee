#= require helpers/uploader

class MySublimeVideo.Helpers.Uploaders.VideoUploader extends MySublimeVideo.Helpers.Uploader
  constructor: (@options = {}) ->
    _.defaults(@options, { title: 'Video files', extensions: 'mov,mp4,m4v' })

    super

    @uploader.bind 'FileUploaded', (up, file) =>
      $("##{file.id} b").html("100%")
      console.log "Let's encode #{@options['url'] + @options['multipart_params']['key'].replace('${filename}', file.name)}!"
