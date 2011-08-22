class MSVStats.Routers.StatsRouter extends Backbone.Router
  initialize: (options) ->
    @sites = new MSVStats.Collections.Sites()
    @sites.fetch()
    # this.navigate('', true)

  routes:
    '': 'test'
    'sites/:token/stats': 'home'

  home: (token) ->
    alert(token)
    
  test:  ->
    alert('bob')
