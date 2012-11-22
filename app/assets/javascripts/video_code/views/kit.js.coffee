class MSVVideoCode.Views.Kit extends Backbone.View
  events:
    'change select#kit_id': 'render'

  #
  # BINDINGS
  #
  render: (event) ->
    MSVVideoCode.previewView.render()

    false


