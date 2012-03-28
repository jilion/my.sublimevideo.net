describe 'Source, Sources', ->

  describe 'MSVVideoCodeGenerator.Models.Source', ->
    beforeEach ->
      @source = new MSVVideoCodeGenerator.Models.Source(_.first(sources))

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
        @source.set(width: 500)
        @source.set(height: 250)
        @source.set(ratio: 0.5)

        @source.setEmbedWidth(500)
        expect(@source.get('embedWidth')).toEqual(500)
        expect(@source.get('embedHeight')).toEqual(250)

        @source.set(keepRatio: false)
        @source.set(embedHeight: 100)
        expect(@source.get('embedWidth')).toEqual(500)
        expect(@source.get('embedHeight')).toEqual(100)

        @source.setKeepRatio(true)
        expect(@source.get('embedWidth')).toEqual(500)
        expect(@source.get('embedHeight')).toEqual(250)

      it 'don\'t recalculate anything when keepRatio is set to false', ->
        @source.set(width: 500)
        @source.set(height: 250)
        @source.set(ratio: 0.5)

        @source.setEmbedWidth(250)
        expect(@source.get('embedWidth')).toEqual(250)
        expect(@source.get('embedHeight')).toEqual(125)

        @source.setKeepRatio(false)
        expect(@source.get('embedWidth')).toEqual(250)
        expect(@source.get('embedHeight')).toEqual(125)

    describe 'setDefaultDataName()', ->
      it 'sets dataName from src without the extension and capitalized', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.mp4')
        @source.setDefaultDataName()

        expect(@source.get('dataName')).toEqual("Dartmoor Foo Bar 12")

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

      it 'maximum is 1280', ->
        @source.setEmbedWidth(5000)
        expect(@source.get('embedWidth')).toEqual(1280)

    describe 'setEmbedHeight()', ->
      it 'sets embedHeight to 100 if it is not a number', ->
        @source.setEmbedHeight('a')
        expect(@source.get('embedHeight')).toEqual(100)

      it 'cast the given height to integer', ->
        @source.setEmbedHeight('250')
        expect(@source.get('embedHeight')).toEqual(250)

      it 'sets the given height casted to integer', ->
        @source.setEmbedHeight(250.4)
        expect(@source.get('embedHeight')).toEqual(250)

      it 'minimum is 100', ->
        @source.setEmbedHeight(50)
        expect(@source.get('embedHeight')).toEqual(100)

      it 'maximum is 720', ->
        @source.setEmbedHeight(9999)
        expect(@source.get('embedHeight')).toEqual(720)

    describe 'setEmbedHeightWithRatio()', ->
      it 'sets embedHeight from embedWidth and ratio', ->
        @source.set(embedWidth:300, ratio:0.5)
        @source.setEmbedHeightWithRatio()
        expect(@source.get('embedHeight')).toEqual(150)

    describe 'setEmbedWidthWithRatio()', ->
      it 'sets embedWidth from embedHeight and ratio', ->
        @source.set(embedHeight:300, ratio:0.5)
        @source.setEmbedWidthWithRatio()
        expect(@source.get('embedWidth')).toEqual(600)

    describe 'extension()', ->
      it 'returns the extension', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.mp4')
        expect(@source.extension()).toEqual('mp4')

      it 'returns the extension', ->
        @source.set(src: '')
        expect(@source.extension()).toEqual('')

    describe 'expectedMimeType()', ->
      it 'returns video/mp4 for mp4 file', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.mp4')
        expect(@source.expectedMimeType()).toEqual('video/mp4')
      it 'returns video/mp4 for m4v file', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.m4v')
        expect(@source.expectedMimeType()).toEqual('video/mp4')

      it 'returns video/webm for webm file', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.webm')
        expect(@source.expectedMimeType()).toEqual('video/webm')

      it 'returns video/ogg for ogv file', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.ogv')
        expect(@source.expectedMimeType()).toEqual('video/ogg')
      it 'returns video/ogg for ogg file', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.ogg')
        expect(@source.expectedMimeType()).toEqual('video/ogg')

      it 'returns the current mime type for unknown file', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.mov')
        @source.set(currentMimeType: 'video/quicktime')
        expect(@source.expectedMimeType()).toEqual('video/quicktime')

    describe 'validMimeType()', ->
      it 'returns true if currentMimeType is empty', ->
        @source.set(currentMimeType: '')
        expect(@source.validMimeType()).toBeTruthy()

      it 'returns true if mime type correspond to the expected mime type', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.m4v')
        @source.set(currentMimeType: 'video/mp4')
        expect(@source.validMimeType()).toBeTruthy()

      it 'returns false if mime type doesn\'t correspond to the expected mime type', ->
        @source.set(src: 'http://sublimevideo.net/demo/dartmoor_foo_bar_12.m4v')
        @source.set(currentMimeType: 'video/webm')
        expect(@source.validMimeType()).toBeFalsy()

    describe 'reset()', ->
      it 'resets the dataName, dataUID, keepRatio, embedWidth, embedHeight and currentMimeType attributes', ->
        @source.set(format: 'webm')
        @source.set(quality: 'hd')
        @source.set(dataName: 'foo')
        @source.set(dataUID: 'bar')
        @source.set(isUsed: false)
        @source.set(keepRatio: false)
        @source.set(embedWidth: 12)
        @source.set(embedHeight: 42)
        @source.set(currentMimeType: 'video/webm')

        expect(@source.get('format')).toEqual('webm')
        expect(@source.get('quality')).toEqual('hd')
        expect(@source.get('dataName')).toEqual('foo')
        expect(@source.get('dataUID')).toEqual('bar')
        expect(@source.get('isUsed')).toBeFalsy()
        expect(@source.get('keepRatio')).toBeFalsy()
        expect(@source.get('embedWidth')).toEqual(12)
        expect(@source.get('embedHeight')).toEqual(42)
        expect(@source.get('currentMimeType')).toEqual('video/webm')

        @source.reset()

        expect(@source.get('format')).toEqual('webm')
        expect(@source.get('quality')).toEqual('hd')
        expect(@source.get('dataName')).toEqual('')
        expect(@source.get('dataUID')).toEqual('')
        expect(@source.get('isUsed')).toBeFalsy()
        expect(@source.get('keepRatio')).toBeTruthy()
        expect(@source.get('embedWidth')).toEqual(null)
        expect(@source.get('embedHeight')).toEqual(null)
        expect(@source.get('currentMimeType')).toEqual('')

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
