class SVStats.Models.SiteUsagesStat extends SVStats.Models.Stat
  defaults:
    
    lh: {} # Loader hits: { ns (non-ssl) => 2, s (ssl) => 1 }
    ph: {} # Player hits: { m (main non-cached) => 3, mc (main cached) => 1, e (extra non-cached) => 3, ec (extra cached) => 1, d (dev non-cached) => 3, dc (dev cached) => 1, i (invalid non-cached) => 3, ic (invalid cached) => 1 }
    fh: 0  # Flash hits
    sr: 0  # S3 Requests
    tr: {} # Traffic (bytes): { s (s3) => 2123, v (voxcast) => 1231 }

  customGet: (selected) ->
    this.get(selected[0])[selected[1]] or 0

class SVStats.Collections.SiteUsagesStats extends SVStats.Collections.Stats
  model: SVStats.Models.SiteUsagesStat
  initialize: -> @selected = []
  url: -> '/stats/site_usages.json'
  id: -> 'site_usages'

  fillColor: (selected) ->
    switch selected[0]
      when 'lh', 'ph', 'fh', 'sr' then 'rgba(74,100,142,0.3)'
      when 'tr' then 'rgba(250,150,100,0.7)'

  color: (selected) ->
    switch selected[0]
      when 'lh', 'ph', 'fh', 'sr' then 'rgba(74,100,142,0.3)'
      when 'tr' then 'rgba(250,150,100,0.7)'

  lineColor: (selected) ->
    switch selected[0]
      when 'lh', 'ph', 'fh', 'sr' then 'rgba(74,100,142,0.3)'
      when 'tr' then 'rgba(250,150,100,0.7)'

  yAxis: (selected) ->
    switch selected[0]
      when 'lh', 'ph', 'fh', 'sr' then 1
      when 'tr' then 3

  title: (selected) ->
    top = switch selected[0]
      when 'lh' then 'Loader hits'
      when 'ph' then 'Player hits'
      when 'fh' then 'Flash hits'
      when 'sr' then 'S3 Requests'
      when 'tr' then 'Traffic (GB)'
      else ''
    type = switch selected[1]
      when 'billable' then 'Billable'
      when 'ns' then 'Non-SSL'
      when 's'
        switch selected[0]
          when 'lh' then 'SSL'
          when 'tr' then 'S3'
      when 'm' then 'Main'
      when 'e' then 'Extra'
      when 'd' then 'Dev'
      when 'i' then 'Invalid'
      when 'v' then 'Voxcast'
      else ''

    "#{type} #{top}"

  customPluck: (selected) ->
    array = []
    from  = this.at(0).id
    to    = this.at(this.length - 1).id
    while from <= to
      stat = this.get(from)
      value = if stat?
        switch selected[0]
          when 'lh'
            switch selected[1]
              when 'all' then stat.customGet(['lh', 'ns']) + stat.customGet(['lh', 's'])
              else stat.customGet(selected)
          when 'ph'
            switch selected[1]
              when 'billable' then stat.customGet([selected[0], 'm']) + stat.customGet([selected[0], 'mc']) + stat.customGet([selected[0], 'e']) + stat.customGet([selected[0], 'ec'])
              else stat.customGet(selected) + stat.customGet([selected[0], "#{selected[1]}c"])
          when 'fh' then stat.get('fh')
          when 'sr' then stat.get('sr')
          when 'tr' then stat.customGet(selected) / (1024 * 1024 * 1024)  # GB
      else
        0
      array.push value
      from += 3600 * 24

    array