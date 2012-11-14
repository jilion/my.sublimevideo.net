describe 'MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper', ->
  describe 'diagnose()', ->
    beforeEach ->
      @video = new MySublimeVideo.Models.Video
        dataUID: 'foo'
        dataName: 'Foo'
        sources: new MySublimeVideo.Collections.Sources([
          new MySublimeVideo.Models.Source(src: 'foo.mp4')
          new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: false)
          new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: false)
          new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: true, currentMimeType: 'video/wrong')
          new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: true, currentMimeType: 'video/wrong')
          new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: true)
        ])
      @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
      @helper.diagnose()

    it 'construct a hash of warnings', ->
      expect(@helper.errors['src_invalid']).toEqual(1)
      expect(@helper.errors['not_found']).toEqual(2)
      expect(@helper.warnings['mime_type_invalid']).toEqual(2)

  describe 'buildMessages()', ->
    describe '1 invalid source', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video
          dataUID: 'foo'
          dataName: 'Foo'
          sources: new MySublimeVideo.Collections.Sources([
            new MySublimeVideo.Models.Source(src: 'foo.mp4')
          ])
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'construct a hash of messages', ->
        expect(@helper.messages['errors'].length).toEqual(1)
        expect(@helper.messages['warnings'].length).toEqual(0)

      it 'has the right content', ->
        expect(@helper.messages['errors'][0]).toEqual("There is one source that isn't a valid URL.")

    describe '2 invalid sources', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video
          dataUID: 'foo'
          dataName: 'Foo'
          sources: new MySublimeVideo.Collections.Sources([
            new MySublimeVideo.Models.Source(src: 'foo.mp4')
            new MySublimeVideo.Models.Source(src: 'foo.mp4')
          ])
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'has the right content', ->
        expect(@helper.messages['errors'][0]).toEqual("There are 2 sources that aren't valid URLs.")

    describe '1 404ed source', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video
          dataUID: 'foo'
          dataName: 'Foo'
          sources: new MySublimeVideo.Collections.Sources([
            new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: false)
          ])
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'construct a hash of messages', ->
        expect(@helper.messages['errors'].length).toEqual(1)
        expect(@helper.messages['warnings'].length).toEqual(0)

      it 'has the right content', ->
        expect(@helper.messages['errors'][0]).toEqual("There is one source that cannot be found.")

    describe '2 404ed sources', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video
          dataUID: 'foo'
          dataName: 'Foo'
          sources: new MySublimeVideo.Collections.Sources([
            new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: false)
            new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: false)
          ])
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'has the right content', ->
        expect(@helper.messages['errors'][0]).toEqual("There are 2 sources that cannot be found.")

    describe '1 source with an invalid MIME Type', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video
          dataUID: 'foo'
          dataName: 'Foo'
          sources: new MySublimeVideo.Collections.Sources([
            new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: true, currentMimeType: 'video/wrong')
          ])
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'construct a hash of messages', ->
        expect(@helper.messages['errors'].length).toEqual(0)
        expect(@helper.messages['warnings'].length).toEqual(1)

      it 'has the right content', ->
        expect(@helper.messages['warnings'][0]).toEqual("There is one source that seems to have an invalid MIME Type.")

    describe '2 404ed sources', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video
          dataUID: 'foo'
          dataName: 'Foo'
          sources: new MySublimeVideo.Collections.Sources([
            new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: true, currentMimeType: 'video/wrong')
            new MySublimeVideo.Models.Source(src: 'http://mydomain.com/foo.mp4', found: true, currentMimeType: 'video/wrong')
          ])
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'has the right content', ->
        expect(@helper.messages['warnings'][0]).toEqual("There are 2 sources that seem to have invalid MIME Types.")

    describe 'missing dataUID', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video(dataUID: '', dataName: 'Foo', sources: new MySublimeVideo.Collections.Sources)
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'construct a hash of messages', ->
        expect(@helper.messages['errors'].length).toEqual(0)
        expect(@helper.messages['warnings'].length).toEqual(1)

      it 'has the right content', ->
        expect(@helper.messages['warnings'][0]).toEqual("We recommend that you provide a UID for this video in the Video settings => Video metadata settings => UID field to make it uniquely identifiable in your Real-Time Statistics dashboard. <a href='http://docs.#{SublimeVideo.Misc.Utils.topDomainHost()}/optimize-for-stats' onclick='window.open(this); return false'>Read more</a>.")

    describe 'missing dataName', ->
      beforeEach ->
        @video = new MySublimeVideo.Models.Video(dataUID: 'foo', dataName: '', sources: new MySublimeVideo.Collections.Sources)
        @helper = new MSVVideoCodeGenerator.Helpers.VideoTagNoticesHelper(@video)
        @helper.buildMessages()

      it 'construct a hash of messages', ->
        expect(@helper.messages['errors'].length).toEqual(0)
        expect(@helper.messages['warnings'].length).toEqual(1)

      it 'has the right content', ->
        expect(@helper.messages['warnings'][0]).toEqual("We recommend that you provide a name for this video in the Video settings => Video metadata settings => Name field to make it easily identifiable in your Real-Time Statistics dashboard. <a href='http://docs.#{SublimeVideo.Misc.Utils.topDomainHost()}/optimize-for-stats' onclick='window.open(this); return false'>Read more</a>.")
