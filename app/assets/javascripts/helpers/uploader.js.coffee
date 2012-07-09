#= require plupload/js/plupload.full

class MySublimeVideo.Helpers.Uploader
  constructor: (@options = {}) ->
    console.log @options
    @uploader = new plupload.Uploader
      runtimes: 'gears,flash,silverlight,browserplus'
      browse_button: 'pickfiles'
      container: 'container'
      max_file_size: '100mb'
      url: @options['url']
      flash_swf_url: '/assets/plupload/js/plupload.flash.swf'
      silverlight_xap_url: '/assets/plupload/js/plupload.silverlight.xap'
      filters: [
        { title: "Image files", extensions: "jpg,gif,png" },
        { title: "Video files", extensions: "mov,mp4,m4v" },
        { title: "Zip files", extensions: "zip" }
      ]
      # resize : { width: 320, height: 240, quality: 90 }
      multipart: true
      multipart_params: @options['multipart_params']

    @uploader.bind 'Init', (up, params) ->
      jQuery('#filelist').html "<div>Current runtime: #{params.runtime}</div>"

    jQuery('#uploadfiles').click (e) =>
      @uploader.start()
      e.preventDefault()

    @uploader.init()

    @uploader.bind 'FilesAdded', (up, files) ->
      jQuery.each files, (i, file) ->
        jQuery('#filelist').append "<div id='#{file.id}'>#{file.name} (#{plupload.formatSize(file.size)}) <b></b></div>"
      up.refresh() # Reposition Flash/Silverlight

    @uploader.bind 'UploadProgress', (up, file) ->
      jQuery("##{file.id} b").html "#{file.percent}%"

    @uploader.bind 'Error', (up, err) ->
      jQuery('#filelist').append "<div>Error: #{err.code}, Message: #{err.message}#{if err.file then ", File: #{err.file.name}" else ""}</div>"
      up.refresh() # Reposition Flash/Silverlight

    @uploader.bind 'FileUploaded', (up, file) ->
      jQuery("##{file.id} b").html("100%")
      alert 'uploaded!'

  getOptions: -> @options
