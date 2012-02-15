describe 'Source, Sources', ->

  describe 'MSVVideoCodeGenerator.Models.Source', ->
    beforeEach ->
      @source = new MSVVideoCodeGenerator.Models.Source(_.first(sources))

    describe 'srcIsUrl()', ->
      it 'returns false when not an URL', ->
        @source.set(src: 'test')
        expect(@source.srcIsUrl()).toBeFalsy()

      it 'returns true when an URL', ->
        @source.set(src: 'http://test.com')
        expect(@source.srcIsUrl()).toBeTruthy()

    describe 'formatQuality()', ->
      it 'check of format', ->
        expect(@source.get('format')).toEqual('mp4')

      it 'check of quality', ->
        expect(@source.get('quality')).toEqual('base')

      it 'returns a concatenation of format and quality separated by a _', ->
        expect(@source.formatQuality()).toEqual('mp4_base')

    describe 'needDataQualityAttribute()', ->
      it 'returns true for hd', ->
        @source.set(quality: 'hd')
        expect(@source.needDataQualityAttribute()).toBeTruthy()

      it 'returns false for base', ->
        @source.set(quality: 'base')
        expect(@source.needDataQualityAttribute()).toBeFalsy()

      it 'returns true for mobile', ->
        @source.set(quality: 'mobile')
        expect(@source.needDataQualityAttribute()).toBeFalsy()

    describe 'setKeepRatio()', ->
      it 'recalculate only embedHeight from embedWidth and ratio when keepRatio is set to true', ->
        @source.set(width: 2000)
        @source.set(height: 1000)
        @source.set(ratio: 0.5)

        @source.setEmbedWidth(1000)
        expect(@source.get('embedWidth')).toEqual(1000)
        expect(@source.get('embedHeight')).toEqual(500)
        @source.set(keepRatio: false)
        @source.set(embedHeight: 100)

        @source.setKeepRatio(true)
        expect(@source.get('embedWidth')).toEqual(1000)
        expect(@source.get('embedHeight')).toEqual(500)

      it 'don\'t recalculate anything when keepRatio is set to false', ->
        @source.set(width: 2000)
        @source.set(height: 1000)
        @source.set(ratio: 0.5)

        @source.set(keepRatio: true)
        @source.setEmbedWidth(1000)
        expect(@source.get('embedWidth')).toEqual(1000)
        expect(@source.get('embedHeight')).toEqual(500)

        @source.setKeepRatio(false)
        expect(@source.get('embedWidth')).toEqual(1000)
        expect(@source.get('embedHeight')).toEqual(500)

    describe 'setDefaultDataName()', ->
      it 'sets dataName from src without the extension and capitalized', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor.mp4')
        @source.setDefaultDataName()

        expect(@source.get('dataName')).toEqual("Dartmoor")

    describe 'setDimensions()', ->
      it 'sets the width, height and ratio', ->
        @source.setDimensions('http://sublimevideo.net/demo/dartmoor.mp4', { width:600, height:364 })
        expect(@source.get('width')).toEqual(600)
        expect(@source.get('height')).toEqual(364)
        expect(@source.get('ratio')).toEqual(364 / 600)
        expect(@source.get('embedWidth')).toEqual(600)

      it 'width > 852, sets the width, height and ratio', ->
        @source.setDimensions('http://sublimevideo.net/demo/dartmoor.mp4', { width:1000, height:364 })
        expect(@source.get('width')).toEqual(1000)
        expect(@source.get('height')).toEqual(364)
        expect(@source.get('ratio')).toEqual(364 / 1000)
        expect(@source.get('embedWidth')).toEqual(852)

    describe 'setEmbedWidth()', ->
      it 'sets embedWidth to 200 if it is not a number', ->
        @source.setEmbedWidth('a')
        expect(@source.get('embedWidth')).toEqual(200)

      it 'cast the given width to integer', ->
        @source.setEmbedWidth('250')
        expect(@source.get('embedWidth')).toEqual(250)

      it 'sets the given width casted to integer', ->
        @source.setEmbedWidth(250.4)
        expect(@source.get('embedWidth')).toEqual(250)

      it 'minimum is 200', ->
        @source.setEmbedWidth(50)
        expect(@source.get('embedWidth')).toEqual(200)

      it 'maximum is 2000', ->
        @source.setEmbedWidth(5000)
        expect(@source.get('embedWidth')).toEqual(2000)

    describe 'setEmbedHeightWithRatio()', ->
      it 'sets embedHeight from embedWidth and ratio', ->
        @source.set(embedWidth:300, ratio:0.5)
        @source.setEmbedHeightWithRatio()
        expect(@source.get('embedHeight')).toEqual(150)

  describe 'MSVVideoCodeGenerator.Collections.Sources', ->
    beforeEach ->
      @sources = new MSVVideoCodeGenerator.Collections.Sources(sources)

    describe 'mp4Base()', ->
      it 'returns the source with format = mp4 and quality = base', ->
        expect(@sources.mp4Base()).toEqual(@sources.models[0])

    describe 'mp4Mobile()', ->
      it 'returns the source with format = mp4 and quality = mobile', ->
        expect(@sources.mp4Mobile()).toEqual(@sources.models[2])

      describe 'no mobile source', ->
        beforeEach ->
          @sources = new MSVVideoCodeGenerator.Collections.Sources([_.first(sources)])

        it 'returns the source with format = mp4 and quality = base', ->
          expect(@sources.mp4Mobile()).toEqual(@sources.mp4Base())

      describe 'mobile source has no src', ->
        beforeEach ->
          @sources.models[2].set(src: '')

        it 'returns the source with format = mp4 and quality = base', ->
          expect(@sources.mp4Mobile()).toEqual(@sources.mp4Base())

      describe 'mobile source has isUsed to false', ->
        beforeEach ->
          @sources.models[2].set(isUsed: false)

        it 'returns the source with format = mp4 and quality = base', ->
          expect(@sources.mp4Mobile()).toEqual(@sources.mp4Base())

    describe 'allByFormat()', ->
      it 'returns all source with format == mp4', ->
        expect(@sources.allByFormat('mp4')).toEqual([@sources.models[0], @sources.models[1], @sources.models[2]])

    describe 'allByQuality()', ->
      it 'returns all source with quality == hd', ->
        expect(@sources.allByQuality('hd')).toEqual([@sources.models[1], @sources.models[4]])

    describe 'allNonBase()', ->
      it 'checks @sources size', ->
        expect(@sources.length).toEqual(5)

      it 'returns only sources with quality != base', ->
        expect(@sources.allNonBase().length).toEqual(3)

    describe 'hdPresent()', ->
      it 'returns true if at least one hd source is present', ->
        expect(@sources.hdPresent()).toBeTruthy()

      describe 'no hd source', ->
        beforeEach ->
          @sources = new MSVVideoCodeGenerator.Collections.Sources([_.first(sources)])

        it 'returns false if no hd source is present', ->
          expect(@sources.hdPresent()).toBeFalsy()

      describe 'hd sources have no src', ->
        beforeEach ->
          @sources.models[1].set(src: '')
          @sources.models[4].set(src: '')

        it 'returns false', ->
          expect(@sources.hdPresent()).toBeFalsy()

      describe 'hd sources have isUsed to false', ->
        beforeEach ->
          @sources.models[1].set(isUsed: false)
          @sources.models[4].set(isUsed: false)

        it 'returns false', ->
          expect(@sources.hdPresent()).toBeFalsy()

    describe 'byQuality()', ->
      it 'returns a source', ->
        expect(@sources.byQuality('hd')).toEqual(@sources.models[1])

    describe 'byFormatAndQuality()', ->
      it 'returns a source', ->
        expect(@sources.byFormatAndQuality(['mp4', 'hd'])).toEqual(@sources.models[1])

      it 'returns null if not found', ->
        expect(@sources.byFormatAndQuality(['foo', 'bar'])).toEqual(null)
