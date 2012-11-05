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
      # resize : { width: 320, height: 240, quality: 90 }
      multipart: true
      multipart_params: @options['multipart_params']

    # @uploader.bind 'Init', (up, params) ->
    #   $('#filelist').html 'Supports drag/drop: ' + (!!up.features.dragdrop)
    #   # $('#filelist').html "<div>Current runtime: #{params.runtime}</div>"

    $('#uploadfiles').click (e) =>
      @uploader.start()
      e.preventDefault()

    @uploader.init()

    @uploader.bind 'FilesAdded', (up, files) ->
      $.each files, (i, file) ->
        $('#filelist').append "<div id='#{file.id}'>#{file.name} (#{plupload.formatSize(file.size)})</div>"
      up.refresh() # Reposition Flash/Silverlight

    @uploader.bind 'UploadProgress', (up, file) ->
      $("##{file.id} b").html "#{file.percent}%"

    @uploader.bind 'Error', (up, err) ->
      $('#filelist').append "<div>Error: #{err.code}, Message: #{err.message}#{if err.file then ", File: #{err.file.name}" else ""}</div>"
      up.refresh() # Reposition Flash/Silverlight

  getOptions: -> @options
