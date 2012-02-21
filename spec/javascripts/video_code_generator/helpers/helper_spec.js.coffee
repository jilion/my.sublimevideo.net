describe 'Helper', ->

  describe 'MSVVideoCodeGenerator.Helpers.Helper', ->
    beforeEach ->
      @helper = new MSVVideoCodeGenerator.Helpers.Helper

    describe 'checkbox()', ->
      it 'return a simple checkbox input tag', ->
        expect(@helper.checkbox()).toEqual("<input type='checkbox' />")

      it 'accepts "id" in options', ->
        expect(@helper.checkbox(id: 'foo')).toEqual("<input type='checkbox' id='foo' />")

      it 'accepts "class" in options', ->
        expect(@helper.checkbox(class: 'bar')).toEqual("<input type='checkbox' class='bar' />")

      it 'accepts "checked => true" in options', ->
        expect(@helper.checkbox(checked: true)).toEqual("<input type='checkbox' checked />")

      it 'accepts "checked => false" (does nothing) in options', ->
        expect(@helper.checkbox(checked: false)).toEqual("<input type='checkbox' />")

      it 'accepts many parameters in options', ->
      expect(@helper.checkbox(id: 'foo', class: 'bar', checked: true)).toEqual("<input type='checkbox' id='foo' class='bar' checked />")
