class MSVVideoCode.Views.Kit extends Backbone.View

  #
  # EVENTS
  #
  events: ->
    'change select#kit_id': 'updateSelectedKitIdentifier'

  updateSelectedKitIdentifier: (event) ->
    MSVVideoCode.kits.select(event.target.value)
