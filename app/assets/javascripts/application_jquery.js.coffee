#= require jquery
#= require jquery_ujs
#= require underscore

window.MySublimeVideo = {}

$ ->
  # Site quick switch
  if $('#site_quick_switch_trigger')
    MySublimeVideo.siteQuickSwitch = new SiteQuickSwitch $('#site_quick_switch_trigger')

class SiteQuickSwitch
  constructor: (triggerLink) ->
    @ul          = $('#site_quick_switch_list')
    @triggerLink = triggerLink
    @token       = triggerLink.data('token')

    triggerLink.click this.showSitesList
    @ul.find('li a').each ->
      if $(this).data('token') is @token
        $(this).click this.hideSitesList
      else
        $(this).click this.changePage

  showSitesList: (event) ->
    event.stopPropagation()
    @triggerLink.hide()
    @ul.addClass('expanded')

  hideSitesList: (event) ->
    if event then event.stopPropagation()
    @ul.removeClass('expanded')
    @triggerLink.show()

  changePage: (event) ->
    event.stopPropagation()
    # Change the active link in the sites' list
    # @ul.find('.active')[0].removeClass('active')
    # event.target.addClass('active')

    # Change the current selected site text
    @triggerLink.update event.target.text()
    this.hideSitesList()
    window.location.href = window.location.href.replace @token, event.target.data('token')
