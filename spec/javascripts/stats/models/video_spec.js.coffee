describe 'Videos', ->
  beforeEach ->
    MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds({id: 1060})
    MSVStats.period = new MSVStats.Models.Period
      type: 'seconds'
      startSecondsTime: 1000 * 1000
      endSecondsTime: 1059 * 1000

  beforeEach ->
    # MSVStats.sites = new MSVStats.Collections.Sites({token: 'site1234'})
    # MSVStats.sites.select('site1234')
    MSVStats.site = new MSVStats.Models.Site()

  describe 'MSVStats.Models.Video', ->

    it 'copies addTime from period', ->
      @video = new MSVStats.Models.Video()
      expect(@video.addTime).toEqual(MSVStats.period.endTime() + 2 * 1000)

    describe 'youTubeId()', ->
      it 'return sources_id if sources_origin is youtube', ->
        video = new MSVStats.Models.Video
          sources_origin: 'youtube'
          sources_id: 'youtube_id'
        expect(video.youTubeId()).toEqual('youtube_id')

      it 'return null if sources_origin is other', ->
        video = new MSVStats.Models.Video
          sources_origin: 'other'
          sources_id: 'other_id'
        expect(video.youTubeId()).toEqual(null)

    describe 'vlTotal() & vvTotal()', ->
      describe 'with vv_sum & vl_sum null', ->
        beforeEach ->
          @video = new MSVStats.Models.Video
            vl_hash: {999: 1, 1001: 2, 1002: 3, 1059: 4, 1060: 5}
            vv_hash: {999: 1, 1001: 2, 1002: 3, 1059: 4, 1060: 5}

        it 'return 6 vlTotal', ->
          expect(@video.vlTotal()).toEqual(9)

        it 'return 15 for vvTotal', ->
          expect(@video.vvTotal()).toEqual(9)

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
        @video = new MSVStats.Models.Video
          vl_hash: {999: 1, 1001: 2, 1002: 3, 1059: 4, 1060: 5}
          vv_hash: {999: 1, 1001: 2, 1002: 3, 1059: 4, 1060: 5}

      it 'return array with missing value', ->
        expect(@video.vvArray()).toEqual([0,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4])


  describe 'MSVStats.Collections.Videos', ->

    describe 'merge()', ->

      describe 'with an existing video', ->
        beforeEach ->
          MSVStats.videos = new MSVStats.Collections.Videos [{
            id: 'video1'
            vl_hash: {60: 1, 61: 2, 62: 3 }
            vv_hash: {60: 1, 61: 2, 62: 3 }
          }]
          @videos = MSVStats.videos

        it 'add data to the end', ->
          @videos.merge [{ id: 63, u: 'video1', vv: 1 }]
          expect(@videos.first().get('vl_hash')).toEqual(60 : 1, 61 : 2, 62 : 3)
          expect(@videos.first().get('vv_hash')).toEqual(60 : 1, 61 : 2, 62 : 3, 63: 1)

        it 'increment last data', ->
          @videos.merge [{ id: 62, u: 'video1', vv: 1 }]
          expect(@videos.first().get('vl_hash')).toEqual(60 : 1, 61 : 2, 62 : 3)
          expect(@videos.first().get('vv_hash')).toEqual(60 : 1, 61 : 2, 62 : 4)

        it 'increment pre-last data', ->
          @videos.merge [{ id: 61, u: 'video1', vl: 1 }]
          expect(@videos.first().get('vl_hash')).toEqual(60 : 1, 61 : 3, 62 : 3)
          expect(@videos.first().get('vv_hash')).toEqual(60 : 1, 61 : 2, 62 : 3)

        it 'adds new video', ->
          @videos.merge [{ id: 62, u: 'video2', n: 'video2', vl: 1 }]
          @video2 = @videos.get('video2')
          expect(@video2.get('vl_hash')).toEqual(62 : 1)
          expect(@video2.get('vv_hash')).toEqual({})

