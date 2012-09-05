MySublimeVideo.UI.prepareVideoTagsFilter = ->
  if (form = $('#js-video_tags_filter_form')).exists()
    $('#js-video_tags_filter_select').on 'change', ->
      $('#table_spinner').show()
      form.submit()
