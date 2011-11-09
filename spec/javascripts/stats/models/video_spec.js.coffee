describe 'MSVStats.Models.Video', ->

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
        MSVStats.period       = new MSVStats.Models.Period(type: 'minutes')
        MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes()
        MSVStats.statsMinutes.reset(minutesStats)
        @video = new MSVStats.Models.Video
          vl_array: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,0,0,0]
          vv_array: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,5,6,0,0,0]

      it 'return 6 vlTotal', ->
        expect(@video.vlTotal()).toEqual(6)

      it 'return 15 for vvTotal', ->
        expect(@video.vvTotal()).toEqual(15)

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
