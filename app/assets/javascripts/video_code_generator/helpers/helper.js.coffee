class MSVVideoCodeGenerator.Helpers.Helper

  checkbox: (options = {}) ->
    this.input('checkbox', options)

  textfield: (options = {}) ->
    this.input('text', options)

  input: (type, options = {}) ->
    html = "<input type='#{type}' "
    html += "id='#{options['id']}' " if options['id']
    html += "class='#{options['class']}' " if options['class']
    html += "placeholder='#{options['placeholder']}' " if options['placeholder']
    html += "size='#{options['size']}' " if options['size']
    html += "maxlength='#{options['maxlength']}' " if options['maxlength']
    html += "readonly " if options['readonly']
    html += "checked " if options['checked']
    html += "/>"
