class MSVVideoCodeGenerator.Views.Kit extends Backbone.View
  events:
    'change select#kit_id': 'render'

  #
  # BINDINGS
  #
  render: (event) ->
    MSVVideoCodeGenerator.previewView.render()

    false


