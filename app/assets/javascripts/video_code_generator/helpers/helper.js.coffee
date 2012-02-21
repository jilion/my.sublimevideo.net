class MSVVideoCodeGenerator.Helpers.Helper

  checkbox: (options = {}) ->
    html = "<input type='checkbox' "
    html += "id='#{options['id']}' " if options['id']
    html += "class='#{options['class']}' " if options['class']
    html += "checked " if options['checked']
    html += "/>"
