class MSVVideoTagBuilder.Views.DemoBootstrap extends Backbone.View

  events:
    'click #use_demo_assets': 'updateUseDemoAssets'

  #
  # EVENTS
  #
  updateUseDemoAssets: (event) ->
    @model.set(useDemoAssets: event.target.checked)
