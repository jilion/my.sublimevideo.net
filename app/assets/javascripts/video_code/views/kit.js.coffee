class MSVVideoCode.Views.Kit extends Backbone.View
  events: ->
    'change select#kit_id': 'updateSelectedKitIdentifier'

  updateSelectedKitIdentifier: (event) ->
    MSVVideoCode.kits.select(event.target.value)
