describe 'Source, Sources', ->

  describe 'MSVVideoTagBuilder.Models.Source', ->
    beforeEach ->
      @source = new MSVVideoTagBuilder.Models.Source(_.first(sources))

    describe 'formatQuality()', ->
      it 'check of format', ->
        expect(@source.get('format')).toEqual('mp4')

      it 'check of quality', ->
        expect(@source.get('quality')).toEqual('normal')

      it 'returns a concatenation of format and quality separated by a _', ->
        expect(@source.formatQuality()).toEqual('mp4_normal')

    describe 'setEmbedWidth()', ->
      it 'sets embedWidth to 0 if it is not a number', ->
        @source.setEmbedWidth('a')
        expect(@source.get('embedWidth')).toEqual(0)

      it 'cast the given width to integer', ->
        @source.setEmbedWidth('2')
        expect(@source.get('embedWidth')).toEqual(2)

      it 'sets the given width casted to integer', ->
        @source.setEmbedWidth(2.4)
        expect(@source.get('embedWidth')).toEqual(2)

    describe 'setKeepRatio()', ->
      it 'sets embedWidth to 0 if it is not a number', ->
        @source.set(width: 3000)
        @source.set(height: 1000)
        @source.set(ratio: 1000/3000)

        @source.setEmbedWidth(1500)
        expect(@source.get('embedWidth')).toEqual(1500)
        expect(@source.get('embedHeight')).toEqual(500)

        @source.set(keepRatio: false)
        @source.setKeepRatio(true)
        expect(@source.get('embedWidth')).toEqual(3000)
        expect(@source.get('embedHeight')).toEqual(1000)

      it 'cast the given width to integer', ->
        @source.setEmbedWidth('2')
        expect(@source.get('embedWidth')).toEqual(2)

      it 'sets the given width casted to integer', ->
        @source.setEmbedWidth(2.4)
        expect(@source.get('embedWidth')).toEqual(2)

  describe 'MSVVideoTagBuilder.Collections.Sources', ->
    beforeEach ->
      @sources = new MSVVideoTagBuilder.Collections.Sources(sources)

    describe 'mp4Normal()', ->
      it 'returns the source with format = mp4 and quality = normal', ->
        expect(@sources.mp4Normal()).toEqual(@sources.models[0])

    describe 'nonNormal()', ->
      it 'checks @sources size', ->
        expect(@sources.length).toEqual(5)

      it 'returns only sources with quality != normal', ->
        expect(@sources.nonNormal().length).toEqual(3)

    describe 'findByFormatAndQuality()', ->
      it 'returns a source', ->
        expect(@sources.findByFormatAndQuality(['mp4', 'hd'])).toEqual(@sources.models[1])

      it 'returns null if not found', ->
        expect(@sources.findByFormatAndQuality(['foo', 'bar'])).toEqual(null)
