class MSVVideoCode.Helpers.VideoTagNoticesHelper
  @MESSAGES_TEMPLATES:
    src_invalid:
      one: "There is one source that isn't a valid URL."
      other: "There are %{count} sources that aren't valid URLs."
    not_found:
      one: "There is one source that cannot be found."
      other: "There are %{count} sources that cannot be found."
    mime_type_invalid:
      one: "There is one source that seems to have an invalid MIME Type."
      other: "There are %{count} sources that seem to have invalid MIME Types."
    uid_missing: "We recommend that you provide a UID for this video in the Video settings => Video metadata settings => UID field to make it uniquely identifiable in your Real-Time Statistics dashboard. <a href='http://docs.#{SublimeVideo.Misc.Utils.topDomainHost()}/addons/stats#setup-for-stats' onclick='window.open(this); return false'>Read more</a>."
    title_missing: "We recommend that you provide a title for this video in the Video settings => Video metadata settings => Title field to make it easily identifiable in your Real-Time Statistics dashboard. <a href='http://docs.#{SublimeVideo.Misc.Utils.topDomainHost()}/addons/stats#setup-for-stats' onclick='window.open(this); return false'>Read more</a>."

  constructor: (@video, @selectedKit) ->

  buildMessages: ->
    this._reset()
    this._diagnoseSources()
    this._diagnoseMetadata()
    this._buildMessages()

    @messages

  _reset: ->
    @counts = { warnings: {}, errors: {} }
    @messages = { warnings: [], errors: [] }

  _diagnoseSources: ->
    _.each @video.get('sources').allUsedNotEmpty(), (source) =>
      if !source.srcIsUrl()
        @counts['errors']['src_invalid'] ?= 0
        @counts['errors']['src_invalid'] += 1
      else if !source.get('found')
        @counts['errors']['not_found'] ?= 0
        @counts['errors']['not_found'] += 1
      else if !source.validMimeType()
        @counts['warnings']['mime_type_invalid'] ?= 0
        @counts['warnings']['mime_type_invalid'] += 1

  _diagnoseMetadata: ->
    if @video.get('origin') isnt 'youtube'
      unless @video.get('uid')
        key = if @video.getSetting('embed', 'type', @selectedKit) is 'auto' then 'errors' else 'warnings'
        @counts[key]['uid_missing'] = true
      @counts['warnings']['title_missing'] = true unless @video.get('title')

  _buildMessages: (key) ->
    _.each @counts, (hash, type) =>
      _.each hash, (count, desc) =>
        @messages[type].push(this._messageFor(desc, count))

  _messageFor: (problemType, problemsCount) ->
    if problemsCount is true
      MSVVideoCode.Helpers.VideoTagNoticesHelper.MESSAGES_TEMPLATES[problemType]
    else
      key = if problemsCount > 1 then 'other' else 'one'
      MSVVideoCode.Helpers.VideoTagNoticesHelper.MESSAGES_TEMPLATES[problemType][key].replace('%{count}', problemsCount)
