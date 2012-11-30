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

  constructor: (@video) ->
    @warnings = { mime_type_invalid: 0 }
    @errors   = { src_invalid: 0, not_found: 0 }
    @messages = { warnings: [], errors: [] }

  diagnose: ->
    _.each @video.get('sources').allUsedNotEmpty(), (source) =>
      if !source.srcIsUrl()
        @errors['src_invalid'] += 1
      else if !source.get('found')
        @errors['not_found'] += 1
      else if !source.validMimeType()
        @warnings['mime_type_invalid'] += 1

  buildMessages: ->
    this.diagnose()
    _.each @errors, (errorsCount, errorType) =>
      @messages['errors'].push(this.messageFor(errorType, errorsCount)) if errorsCount > 0

    _.each @warnings, (warningsCount, warningType) =>
      @messages['warnings'].push(this.messageFor(warningType, warningsCount)) if warningsCount > 0

    if @video.get('origin') isnt 'youtube' and !@video.get('dataUID')
      @messages['warnings'].push "We recommend that you provide a UID for this video in the Video settings => Video metadata settings => UID field to make it uniquely identifiable in your Real-Time Statistics dashboard. <a href='http://docs.#{SublimeVideo.Misc.Utils.topDomainHost()}/optimize-for-stats' onclick='window.open(this); return false'>Read more</a>."

    if @video.get('origin') isnt 'youtube' and !@video.get('dataName')
      @messages['warnings'].push "We recommend that you provide a name for this video in the Video settings => Video metadata settings => Name field to make it easily identifiable in your Real-Time Statistics dashboard. <a href='http://docs.#{SublimeVideo.Misc.Utils.topDomainHost()}/optimize-for-stats' onclick='window.open(this); return false'>Read more</a>."

    @messages

  messageFor: (problemType, problemsCount) ->
    key = if problemsCount > 1 then 'other' else 'one'
    MSVVideoCode.Helpers.VideoTagNoticesHelper.MESSAGES_TEMPLATES[problemType][key].replace('%{count}', problemsCount)
