class MSVVideoCode.Views.Kit extends Backbone.View

  events:
    'change select#kit_id': 'updateSelectedKitIdentifier'

  #
  # EVENTS
  #
  updateSelectedKitIdentifier: (event) ->
    MSVVideoCode.kits.select(event.target.value)
