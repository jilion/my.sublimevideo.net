#= require plupload/js/plupload.full

MySublimeVideo.Helpers.Uploaders = {}

class MySublimeVideo.Helpers.Uploader
  constructor: (@options = {}) ->
    @uploader = new plupload.Uploader
      runtimes: 'html5,flash'
      browse_button: 'pickfiles'
      container: 'container'
      drop_element: 'dragdrop'
      max_file_size: '100mb'
      url: @options['url']
      flash_swf_url: '/assets/plupload/js/plupload.flash.swf'
      filters: [
        { title: @options['title'], extensions: @options['extensions'] }
      ]
      multipart: true
      multipart_params: @options['multipart_params']
      headers:
        'Accept': 'text/javascript'

    # @uploader.bind 'Init', (up, params) ->
    #   $('#filelist').html 'Supports drag/drop: ' + (!!up.features.dragdrop)
    #   # $('#filelist').html "<div>Current runtime: #{params.runtime}</div>"

    @uploader.init()

    @uploader.bind 'FilesAdded', (up, files) ->
      $.each files, (i, file) ->
        $('#uploader_error').text ''
        $('#filelist').append "<div class='file'>#{file.name}</div>"
        $('#uploadfiles').show()
      up.refresh() # Reposition Flash/Silverlight

  getOptions: -> @options
