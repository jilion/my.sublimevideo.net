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
