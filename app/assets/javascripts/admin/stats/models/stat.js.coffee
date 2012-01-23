class SVStats.Models.Stat extends Backbone.Model
  time: -> parseInt(this.id) * 1000
  date: -> new Date(this.time())

class SVStats.Collections.Stats extends Backbone.Collection
  initialize: -> @selected = [['active']]
  chartType: (selected) -> 'spline'
  yAxis: (selected) -> 0
  startTime: -> this.at(0).time()
  fillColor: (selected) -> null
  color: (selected) -> null
  lineColor: (selected) -> null
  shadow: (selected) -> false

  currentlySelected: (selection) ->
    joinedSelection = selection.join('.')
    result = false

    _.each @selected, (selected) ->
      result = true if !result and selected.join('.') is joinedSelection

    result

  select: (newSelection) ->
    console.log('select');
    console.log(newSelection);
    console.log(@selected);
    @selected.push newSelection
    console.log(@selected);

  unselect: (oldSelection) ->
    joinedOldSelection = oldSelection.join('.')
    console.log('unselect');
    console.log(oldSelection);
    console.log(@selected);

    index = -1
    i = 0
    _.each @selected, (selected) ->
      index = i if selected.join('.') is joinedOldSelection
      i += 1

    @selected.splice(index, 1) # remove the selection from the current selection
    console.log(@selected);

  recursiveHashSum: (hash) ->
    sum = 0
    if _.isNumber(hash)
      sum = hash
    else
      _.each _.values(hash), (value) =>
        sum += this.recursiveHashSum(value)

    sum
