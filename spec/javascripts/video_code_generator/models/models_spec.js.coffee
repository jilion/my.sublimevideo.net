describe 'Builder', ->

  describe 'MSVVideoCodeGenerator.Models.Builder', ->
    beforeEach ->
      @builder          = new MSVVideoCodeGenerator.Models.Builder
      @matchingSite1    = new MySublimeVideo.Models.Site(hostname: 'rymai.com')
      @matchingSite2    = new MySublimeVideo.Models.Site(hostname: 'rymai.tv', extra_hostnames: 'rymai.me, rymai.com')
      @matchingSite3    = new MySublimeVideo.Models.Site(hostname: 'rymai.me', wildcard: true)
      @matchingSite4    = new MySublimeVideo.Models.Site(hostname: 'rymai.me', path: 'foo')
      @notMatchingSite1 = new MySublimeVideo.Models.Site(hostname: 'rymai.me', extra_hostnames: 'rymai.tv, rymai.net')
      @notMatchingSite2 = new MySublimeVideo.Models.Site(hostname: 'rymai.com')

    describe 'sitesHostnamesMatchUrl()', ->
      it 'match hostname', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite1, 'http://rymai.com')).toBeTruthy()

      it 'match https urls', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite1, 'https://rymai.com')).toBeTruthy()

      it 'match extra hostname', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite2, 'http://rymai.com')).toBeTruthy()

      it 'match with wildcard', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite3, 'http://dev.rymai.me')).toBeTruthy()

      it 'match with right path 1', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite4, 'http://rymai.me/foo')).toBeTruthy()

      it 'match with right path 2', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite4, 'http://rymai.me/foo/bar')).toBeTruthy()

      it 'dont match when hostname not present', ->
        expect(@builder.sitesHostnamesMatchUrl(@notMatchingSite1, 'http://rymai.com')).toBeFalsy()

      it 'dont match even if hostname is included in URL', ->
        expect(@builder.sitesHostnamesMatchUrl(@notMatchingSite2, 'http://staging-rymai.com')).toBeFalsy()

      it 'match with wrong path', ->
        expect(@builder.sitesHostnamesMatchUrl(@matchingSite4, 'http://rymai.me/bar')).toBeFalsy()
