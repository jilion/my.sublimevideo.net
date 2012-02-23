describe 'Asset', ->

  describe 'MSVVideoCodeGenerator.Models.Asset', ->
    beforeEach ->
      @asset = new MSVVideoCodeGenerator.Models.Asset

    describe 'srcIsEmpty()', ->
      it 'returns true when empty', ->
        @asset.set(src: '')
        expect(@asset.srcIsEmpty()).toBeTruthy()

      it 'returns false when not empty and not an URL', ->
        @asset.set(src: 'test')
        expect(@asset.srcIsEmpty()).toBeFalsy()

      it 'returns false when an URL', ->
        @asset.set(src: 'http://test.com')
        expect(@asset.srcIsEmpty()).toBeFalsy()

    describe 'srcIsUrl()', ->
      it 'returns false when empty', ->
        @asset.set(src: '')
        expect(@asset.srcIsUrl()).toBeFalsy()

      it 'returns false when not empty and not an URL', ->
        @asset.set(src: 'test')
        expect(@asset.srcIsUrl()).toBeFalsy()

      it 'returns true when an URL', ->
        @asset.set(src: 'http://test.com')
        expect(@asset.srcIsUrl()).toBeTruthy()

    describe 'srcIsEmptyOrUrl()', ->
      it 'returns true when empty', ->
        @asset.set(src: '')
        expect(@asset.srcIsEmptyOrUrl()).toBeTruthy()

      it 'returns false when not empty and not an URL', ->
        @asset.set(src: 'test')
        expect(@asset.srcIsEmptyOrUrl()).toBeFalsy()

      it 'returns true when an URL', ->
        @asset.set(src: 'http://test.com')
        expect(@asset.srcIsEmptyOrUrl()).toBeTruthy()
