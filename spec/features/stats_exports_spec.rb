require 'spec_helper'

feature 'StatsExport' do
  let(:video_tag) { VideoTag.new(uid: 'video_uid', title: 'My Video') }

  background do
    sign_in_as :user_with_site
    @site = @current_user.sites.last
    create(:billable_item, site: @site, item: @stats_addon_plan_2)
    create(:site_day_stat, t: @site.token, d: 3.days.ago.midnight.to_i,
      pv: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:site_day_stat, t: @site.token, d: 5.days.ago.midnight.to_i,
      pv: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:video_day_stat, st: @site.token, u: video_tag.uid, d: 3.days.ago.midnight.to_i,
      vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:video_day_stat, st: @site.token, u: video_tag.uid, d: 5.days.ago.midnight.to_i,
      vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    Sidekiq::Worker.clear_all
    clear_emails

    stub_api_for(VideoTag) do |stub|
      stub.get("/private_api/sites/#{@site.token}/video_tags") { |env| [200, {}, [video_tag].to_json] }
      stub.get("/private_api/sites/#{@site.token}/video_tags/video_uid") { |env| [200, {}, video_tag.to_json] }
    end
  end

  scenario "request and download stats exports", :js do
    go 'my', "/sites/#{@site.token}/stats"

    current_url.should match %r{sites/#{@site.token}/stats}

    click_button('Export Data')

    sleep 0.01 until Sidekiq::Worker.jobs.size == 1
    Sidekiq::Worker.drain_all

    open_email(@current_user.email)
    stat_export_id = StatsExport.last.id
    current_email.body.should match %r(stats/exports/#{stat_export_id})

    go 'my', "/stats/exports/#{stat_export_id}"
    # File can't be downloaded directly from S3 because of Fog.mock!
    current_url.should match(
      %r{https://s3\.amazonaws\.com/#{S3Wrapper.buckets['stats_exports']}/uploads/stats_exports/stats_export\.#{@site.hostname}\.\d+-\d+\.csv\.zip\?AWSAccessKeyId=#{S3Wrapper.access_key_id}&Signature=foo&Expires=\d+}
    )

    # Verify zip content
    tempzip = Tempfile.open(['temp', '.zip'])
    File.open(tempzip, 'w', encoding: 'ASCII-8BIT') { |f| f.write(StatsExport.last.file.file.read) }
    zip = Zip::ZipFile.open(tempzip.path)
    zip.read(zip.first).should eq <<-EOF
uid,title,loads_count,views_count,embed_loads_count,embed_views_count
video_uid,My Video,24,24,202,202
    EOF
    tempzip.close
  end

end
