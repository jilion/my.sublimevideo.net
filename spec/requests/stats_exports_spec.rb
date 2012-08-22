require 'spec_helper'

feature 'StatsExport' do
  background do
    sign_in_as :user
    @site = create(:site, user: @current_user, plan_id: @paid_plan.id)
    @video_tag = create(:video_tag, st: @site.token, u: 'video_uid', uo: 'a', n: 'My Video', no: 'a')
    create(:site_day_stat, t: @site.token, d: 3.days.ago.midnight.to_i,
      pv: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:site_day_stat, t: @site.token, d: 5.days.ago.midnight.to_i,
      pv: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:video_day_stat, st: @site.token, u: @video_tag.u, d: 3.days.ago.midnight.to_i,
      vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    create(:video_day_stat, st: @site.token, u: @video_tag.u, d: 5.days.ago.midnight.to_i,
      vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    Delayed::Job.delete_all
  end

  scenario "request and download stats exports", :js, :fog_mock do
    go 'my', "/sites/stats/#{@site.token}"

    click_button('Export Data')

    sleep 0.01 until Delayed::Job.count == 1
    $worker.work_off

    open_email(@current_user.email)
    current_email.find('a', text: /stats\/exports/i).click

    # File can't be downloaded directly from S3 because of Fog.mock!
    current_url.should match(
      %r{https://s3\.amazonaws\.com/#{S3.buckets['stats_exports']}/uploads/stats_exports/stats_export\.#{@site.hostname}\.\d+-\d+\.csv\.zip\?AWSAccessKeyId=#{S3.access_key_id}&Signature=foo&Expires=\d+}
    )

    # Verify zip content
    tempzip = Tempfile.open(['temp', '.zip'])
    File.open(tempzip, 'w') { |f| f.write(StatsExport.last.file.file.read) }
    zip = Zip::ZipFile.open(tempzip.path)
    zip.read(zip.first).should eq <<-EOF
uid,name,loads_count,views_count,embed_loads_count,embed_views_count
video_uid,My Video,24,24,202,202
    EOF
    tempzip.close
  end

end
