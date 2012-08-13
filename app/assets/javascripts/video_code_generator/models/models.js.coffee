class MSVVideoCodeGenerator.Models.Builder extends Backbone.Model
  defaults:
    builderClass: 'standard'
    startWithHd: false
    demoAssetsUsed: false

  sitesHostnamesMatchUrl: (site, url) ->
    hostnameMatch = this.hostnameRegex(site.get('hostname'), site.get('wildcard'), site.get('path')).test(url)
    extraHostnameMatch = site.get('extra_hostnames')? and _.find site.get('extra_hostnames').split(','), (hostname) =>
      this.hostnameRegex(hostname, site.get('wildcard'), site.get('path')).test(url)
    hostnameMatch or extraHostnameMatch

  hostnameRegex: (hostname, wildcard, path) ->
    ///https?:\/\/(#{if wildcard? then '.*' else 'www'}\.)?#{hostname.trim()}#{if path? then "\/#{path}(\/.*|$)" else '(\/.*$|$)'}///

class MSVVideoCodeGenerator.Models.Iframe extends MSVVideoCodeGenerator.Models.Asset
  defaults:
    src: ''
    width: null
    height: null

class MSVVideoCodeGenerator.Models.Loader extends Backbone.Model
  defaults:
    site: null
    ssl: false
