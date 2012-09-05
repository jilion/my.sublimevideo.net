MySublimeVideo.UI.prepareVideoTagsFilter = ->
  if (form = $('#js-video_tags_filter_form')).exists()
    $('#js-video_tags_filter_select').on 'change', ->
      SublimeVideo.UI.Table.showSpinner()
      form.submit()
      if history and history.pushState?
        history.pushState({ isHistory: true }, document.title, "#{form.attr('action')}?#{form.serialize() }")
