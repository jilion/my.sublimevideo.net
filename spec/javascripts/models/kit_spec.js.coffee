describe 'MySublimeVideo.Collections.Kits', ->
  beforeEach ->
    @kits = new MySublimeVideo.Collections.Kits([
      { 'identifier': '1', 'settings': { 'a': 'b' } },
      { 'identifier': '2', 'settings': { 'c': 'd' } }
    ])

  describe 'select()', ->
    it 'set the @selected property', ->
      @kits.select('2')

      expect(@kits.selected.get('identifier')).toEqual('2')
