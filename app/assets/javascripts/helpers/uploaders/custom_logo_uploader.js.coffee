#= require helpers/uploader

class MySublimeVideo.Helpers.Uploaders.CustomLogoUploader extends MySublimeVideo.Helpers.Uploader
  constructor: (@options = {}) ->
    _.defaults(@options, { title: 'Custom logo', extensions: 'png' })

    super @options

    @uploader.bind 'FilesAdded', (up, files) ->
      $.each files, (i, file) ->
        $('#notices').text ''
        $('#dragdrop').text file.name
        $('#uploadfiles').show()
      up.refresh() # Reposition Flash/Silverlight

    @uploader.bind 'Error', (up, err) =>
      message = switch err.code
        when -601 # file extension error
          "Your logo must be a .#{@options['extensions'].split(',').join(', .')} file."
        else
          "An error has occured, please retry."
          # "Error: #{err.code}, Message: #{err.message}#{if err.file then ", File: #{err.file.name}" else ""}"
      $('#notices').html "<div class='notice error'>#{message}</div>"
      $('#spinner').data().spinner.stop()
      $('#uploadfiles').hide()
      up.refresh() # Reposition Flash/Silverlight

    @uploader.bind 'UploadProgress', (up, file) ->
      $('#preview_custom_logo').css(opacity: 0.5)
      $('#spinner').spin
        color:  '#596c8a'
        lines:  10
        length: 4
        width:  2
        radius: 4
        speed:  1
        trail:  50
        shadow: false
      $("##{file.id} b").html "#{file.percent}%"

    @uploader.bind 'FileUploaded', (up, file, response) =>
      $('#filelist').text ''
      $('#notices').text ''
      eval(response.response)
