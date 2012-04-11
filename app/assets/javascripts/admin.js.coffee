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
