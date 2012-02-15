describe 'MSV.Models.Site', ->
  beforeEach ->
    console.log(MSV);
    console.log(MSVVideoCodeGenerator);
    @site = new MSV.Models.Site

  describe 'title()', ->
    it 'returns hostname if present', ->
      @site.set(hostname: 'sublimevideo.net')
      expect(@site.title()).toEqual('sublimevideo.net')

    it 'returns token if hostname not present', ->
      @site.set(token: '1234abcd')
      expect(@site.title()).toEqual('#1234abcd')
