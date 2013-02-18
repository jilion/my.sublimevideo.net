#= require ./trend

class AdminSublimeVideo.Models.SiteUsagesTrend extends AdminSublimeVideo.Models.Trend
  defaults:
    lh: {} # Loader hits: { ns (non-ssl) => 2, s (ssl) => 1 }
    ph: {} # Player hits: { m (main non-cached) => 3, mc (main cached) => 1, e (extra non-cached) => 3, ec (extra cached) => 1, d (dev non-cached) => 3, dc (dev cached) => 1, i (invalid non-cached) => 3, ic (invalid cached) => 1 }
    fh: 0  # Flash hits
    sr: 0  # S3 Requests
    tr: {} # Traffic (bytes): { s (s3) => 2123, v (voxcast) => 1231 }

  customGet: (selected) ->
    this.get(selected[0])[selected[1]] or 0

class AdminSublimeVideo.Collections.SiteUsagesTrends extends AdminSublimeVideo.Collections.Trends
  model: AdminSublimeVideo.Models.SiteUsagesTrend
  url: -> '/trends/site_usages.json'
  id: -> 'site_usages'
  yAxis: (selected) ->
    switch selected[0]
      when 'lh', 'ph', 'fh', 'sr' then 3
      when 'tr' then 5

  title: (selected) ->
    top = switch selected[0]
      when 'lh' then 'Loader hits'
      when 'ph' then 'Player hits'
      when 'fh' then 'Flash hits'
      when 'sr' then 'S3 Requests'
      when 'tr' then 'Traffic'
      else ''
    type = switch selected[1]
      when 'billable' then 'Billable '
      when 'ns' then 'Non-SSL '
      when 's'
        switch selected[0]
          when 'lh' then 'SSL '
          when 'tr' then 'S3 '
      when 'm' then 'Main '
      when 'e' then 'Extra '
      when 'd' then 'Dev '
      when 'i' then 'Invalid '
      when 'v' then 'Voxcast '
      else ''

    "#{type}#{top}"

  customPluck: (selected, from = null, to = null) ->
    array = []
    from  ||= this.at(0).id
    to    ||= this.at(this.length - 1).id

    while from <= to
      trend = this.get(from)
      value = if trend?
        switch selected[0]
          when 'lh'
            switch selected[1]
              when 'all' then trend.customGet(['lh', 'ns']) + trend.customGet(['lh', 's'])
              else trend.customGet(selected)

          when 'ph'
            switch selected[1]
              when 'all' then trend.customGet([selected[0], 'm']) + trend.customGet([selected[0], 'mc']) + trend.customGet([selected[0], 'e']) + trend.customGet([selected[0], 'ec']) + trend.customGet([selected[0], 'd']) + trend.customGet([selected[0], 'dc']) + trend.customGet([selected[0], 'i']) + trend.customGet([selected[0], 'ic'])

              when 'billable' then trend.customGet([selected[0], 'm']) + trend.customGet([selected[0], 'mc']) + trend.customGet([selected[0], 'e']) + trend.customGet([selected[0], 'ec'])

              else trend.customGet(selected) + trend.customGet([selected[0], "#{selected[1]}c"])

          when 'fh' then trend.get('fh')
          when 'sr' then trend.get('sr')
          when 'tr' then trend.customGet(selected) / (1024 * 1024 * 1024)  # GB
      else
        0

      array.push value
      from += 3600 * 24

    array
