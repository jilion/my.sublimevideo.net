describe 'Videos', ->
  beforeEach ->
    MSVStats.sites = new MSVStats.Collections.Sites({token: 'site1234'})
    MSVStats.sites.select('site1234')

  describe 'MSVStats.Models.Video', ->
    beforeEach ->
      MSVStats.videos = new MSVStats.Collections.Videos()
      MSVStats.videos.endTime = 62000

    it 'copies endTime from collection', ->
      @video = new MSVStats.Models.Video()
      expect(@video.endTime).toEqual(MSVStats.videos.endTime)

    describe 'currentSources()', ->
      beforeEach ->
        @video = new MSVStats.Models.Video
          cs: ['source1', 'source3', 'source4']
          s:
            source1:
              u: 'http://videos.sublimevideo.net/source1.mp4'
              q: 'base'
              f: 'mp4'
              r: '460x340'
            source2:
              u: 'http://videos.sublimevideo.net/source2.mp4'
              q: 'base'
              f: 'mp4'
              r: '460x340'
            source3:
              u: 'http://videos.sublimevideo.net/source3.mp4'
              q: 'base'
              f: 'mp4'
              r: '460x340'

      it 'returns first source if no mobile source', ->
        expect(@video.currentSources()).toEqual([
          {
            u: 'http://videos.sublimevideo.net/source1.mp4'
            q: 'base'
            f: 'mp4'
            r: '460x340'
          }
          {
            u: 'http://videos.sublimevideo.net/source3.mp4'
            q: 'base'
            f: 'mp4'
            r: '460x340'
          }
        ])

    describe 'width() & height()', ->
      beforeEach ->
        @video = new MSVStats.Models.Video
          z: '1280x720'

      it 'return 1280 for width', ->
        expect(@video.width()).toEqual(1280)

      it 'return 720 for height', ->
        expect(@video.height()).toEqual(720)

    describe 'vlTotal() & vvTotal()', ->

      describe 'with vv_sum & vl_sum null', ->
        beforeEach ->
          MSVStats.period       = new MSVStats.Models.Period(type: 'seconds')
          MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds({id: 1001})
          @video = new MSVStats.Models.Video
            vl_hash: {1000: 1, 1001: 2, 1002: 3}
            vv_hash: {1000: 1, 1001: 2, 1002: 3}

        it 'return 6 vlTotal', ->
          expect(@video.vlTotal()).toEqual(3)

        it 'return 15 for vvTotal', ->
          expect(@video.vvTotal()).toEqual(3)

      describe 'with vv_sum & vl_sum set', ->
        beforeEach ->
          @video = new MSVStats.Models.Video
            vl_sum: 2
            vv_sum: 1
            vl_array: [1,2,3]
            vv_array: [4,5,6]

        it 'return 1 vlTotal', ->
          expect(@video.vlTotal()).toEqual(2)

        it 'return 2 for vvTotal', ->
          expect(@video.vvTotal()).toEqual(1)

    describe 'vvArray()', ->
      beforeEach ->
        MSVStats.period       = new MSVStats.Models.Period(type: 'seconds')
        MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds({id: 1060})
        @video = new MSVStats.Models.Video
          vl_hash: {1000: 1, 1001: 2, 1002: 3}
          vv_hash: {1000: 1, 1001: 2, 1002: 3}

      it 'return array with missing value', ->
        expect(@video.vvArray()).toEqual([0, 1])


  describe 'MSVStats.Collections.Videos', ->

    describe 'addEmptyNewStats()', ->
      beforeEach ->
        @videos = new MSVStats.Collections.Videos [{
          id: 'video1'
          vl_array: [1,2,3]
          vv_array: [1,2,3]
        }]

      it 'adds 0 to vl_array & vv_array', ->
        @videos.addEmptyNewStats(1000)
        expect(@videos.first().get('vl_array')).toEqual([1,2,3,0])
        expect(@videos.first().get('vv_array')).toEqual([1,2,3,0])

      it 'updates video endTime', ->
        @videos.addEmptyNewStats(1000)
        expect(@videos.first().endTime).toEqual(1000)

      it 'skips update if already up-to-date', ->
        @videos.addEmptyNewStats(1000)
        expect(@videos.first().get('vl_array')).toEqual([1,2,3,0])
        @videos.addEmptyNewStats(1000)
        expect(@videos.first().get('vl_array')).toEqual([1,2,3,0])

    describe 'merge()', ->

      describe 'with an existing video', ->
        beforeEach ->
          MSVStats.videos = new MSVStats.Collections.Videos [{
            id: 'video1'
            vl_array: [1,2,3]
            vv_array: [1,2,3]
          }]
          MSVStats.videos.endTime = 62000
          @videos = MSVStats.videos

        it 'add data to the end', ->
          @videos.merge [{ id: 63, u: 'video1', vv: 1 }]
          expect(@videos.first().get('vv_array')).toEqual([1,2,3,1])
          expect(@videos.first().get('vl_array')).toEqual([1,2,3,0])
          expect(@videos.first().endTime).toEqual(63000)

        it 'increment last data', ->
          @videos.merge [{ id: 62, u: 'video1', vv: 1 }]
          expect(@videos.first().get('vv_array')).toEqual([1,2,4])
          expect(@videos.first().get('vl_array')).toEqual([1,2,3])
          expect(@videos.first().endTime).toEqual(62000)

        it 'increment pre-last data', ->
          @videos.merge [{ id: 61, u: 'video1', vl: 1 }]
          expect(@videos.first().get('vv_array')).toEqual([1,2,3])
          expect(@videos.first().get('vl_array')).toEqual([1,3,3])
          expect(@videos.first().endTime).toEqual(62000)

        it 'adds new video', ->
          @videos.merge [{ id: 62, u: 'video2', n: 'video2', vl: 1 }]
          @video2 = @videos.get('video2')
          expect(_.last(@video2.get('vl_array'))).toEqual(1)
          expect(_.last(@video2.get('vv_array'))).toEqual(0)
          expect(@video2.endTime).toEqual(62000)

