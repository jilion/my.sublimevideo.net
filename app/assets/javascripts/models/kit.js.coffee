class MySublimeVideo.Models.Kit extends Backbone.Model
  defaults:
    settings: {}

  getSetting: (addonName, settingName) ->
    if addonSettings = this.get('settings')[addonName]
      if setting = addonSettings[settingName]
        return setting

    ''

class MySublimeVideo.Collections.Kits extends Backbone.Collection
  model: MySublimeVideo.Models.Kit

  setDefaultKit: (identifier) ->
    @defaultKit = this.byIdentifier(identifier)

  defaultKitSelected: ->
    @selected is @defaultKit

  byIdentifier: (identifier) ->
    this.find (kit) -> kit.get('identifier') is identifier

  select: (identifier) ->
    @selected = this.byIdentifier(identifier)
    this.trigger('change')
