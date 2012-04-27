#= require underscore
#= require highcharts/highcharts

jQuery.fn.exists = -> @length > 0

window.AdminSublimeVideo =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

jQuery(document).ready ->

  ## Live Search form
  if (searchInput = jQuery('#search_input')).exists()
    form = searchInput.parent('form')
    url  = form.attr('action')

    searchInput.on 'keyup', (event) ->
      unless _.include([17, 37, 38, 39, 40, 91], event.which)
        jQuery('#table_spinner').show()
        params = form.serialize()
        jQuery.ajax url,
          type: form.attr('method') || 'post'
          dataType: 'script'
          data: params
          complete: (jqXHR, textStatus) ->
            jQuery('#table_spinner').hide()
            if history && history.pushState
              history.replaceState null, document.title, "#{url}?#{params}"

      false

  ## Tags autocomplete
  if (tagInput = jQuery('.tags')).exists()
    form      = tagInput.parent('form')
    urlPrefix = if /user/.test(form.attr('action')) then 'users' else 'sites'

    tagInput.on 'keyup', (event) ->
      unless _.include([17, 37, 38, 39, 40, 91], event.which)
        word = jQuery.trim(_.last(form.find('input[type=text]').first().attr('value').split(',')))
        if /\S{2,}/.test(word)
          jQuery('#table_spinner').show()
          jQuery.ajax "/#{urlPrefix}/autocomplete_tag_list",
            type: 'get'
            dataType: 'script'
            data: "word=#{word}"
            complete: (jqXHR, textStatus) ->
              jQuery('#table_spinner').hide()

      false

  ## Filters
  if (filters = jQuery('.filters')).exists()
    filters.find('a.remote').each (index, link) ->
      jQuery(this).click (e) ->
        filters.find('a.remote.active').removeClass 'active'
        jQuery(link).addClass 'active'