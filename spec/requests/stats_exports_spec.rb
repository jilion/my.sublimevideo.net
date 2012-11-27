require 'spec_helper'

feature 'StatsExport' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user)
    Service::Site.new(@site).create
    create(:billable_item, site: @site, item: @stats_addon_plan_2)
    @video_tag = create(:video_tag, site: @site, uid: 'video_uid', name: 'My Video')
    create(:site_day_stat, t: @site.token, d: 3.days.ago.midnight.to_i,
      pv: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:site_day_stat, t: @site.token, d: 5.days.ago.midnight.to_i,
      pv: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:video_day_stat, st: @site.token, u: @video_tag.uid, d: 3.days.ago.midnight.to_i,
      vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:video_day_stat, st: @site.token, u: @video_tag.uid, d: 5.days.ago.midnight.to_i,
      vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    Sidekiq::Worker.clear_all
    clear_emails
  end

  scenario "request and download stats exports", :js do
    go 'my', "/sites/#{@site.token}/stats"

    current_url.should match %r{sites/#{@site.token}/stats}

    click_button('Export Data')

    sleep 0.01 until Sidekiq::Worker.jobs.size == 1
    Sidekiq::Worker.drain_all

    open_email(@current_user.email)
    stat_export_id = StatsExport.last.id
    stats_export_url = current_email.find('a', text: %r{stats/exports}).text
    stats_export_url.should match(%r(stats/exports/#{stat_export_id}))

    go 'my', "/stats/exports/#{stat_export_id}"
    # File can't be downloaded directly from S3 because of Fog.mock!
    current_url.should match(
      %r{https://s3\.amazonaws\.com/#{S3.buckets['stats_exports']}/uploads/stats_exports/stats_export\.#{@site.hostname}\.\d+-\d+\.csv\.zip\?AWSAccessKeyId=#{S3.access_key_id}&Signature=foo&Expires=\d+}
    )

    # Verify zip content
    tempzip = Tempfile.open(['temp', '.zip'])
    File.open(tempzip, 'w', encoding: 'ASCII-8BIT') { |f| f.write(StatsExport.last.file.file.read) }
    zip = Zip::ZipFile.open(tempzip.path)
    zip.read(zip.first).should eq <<-EOF
uid,name,loads_count,views_count,embed_loads_count,embed_views_count
video_uid,My Video,24,24,202,202
    EOF
    tempzip.close
  end

end
