# Sites ith active videos without Schooltube & Railscast
sites = Site.where{(last_30_days_video_tags > 0) & (token.not_in ['2xrynuh2', '3s7oes9q'])}.scoped

sum = sites.count
# => 3830

# Average video tag per site
sites.sum(:last_30_days_video_tags) / sum
# => 21

# Average billable video views per month per site
(sites.sum(:last_30_days_main_video_views) + sites.sum(:last_30_days_extra_video_views)  + sites.sum(:last_30_days_embed_video_views)) / sum
# => 647

# Average video view per month per video
# 647 / 21 => 30


# id token hostname state plan all_time_bill_plays all_time_video_tags last_30d_bill_plays last_30d_video_tags

CSV.generate do |csv|
  csv << ["id", "token", "hostname", "state", "plan", "all_billed_plays", "all_video_tags", "last_30d_bill_plays", "last_30d_video_tags"]
  Site.all.each do |site|
    plan = site.plan.try(:title)
    all_billed_plays = Stat::Site::Day.views_sum(token: site.token, billable_only: true)
    all_video_tags = VideoTag.count(_site_token: site.token)
    last_30d_bill_plays = site.last_30_days_main_video_views.to_i + site.last_30_days_extra_video_views.to_i
    last_30d_video_tags = site.last_30_days_video_tags.to_i
    csv << [site.id, site.token, site.hostname.presence, site.state, plan, all_billed_plays, all_video_tags, last_30d_bill_plays, last_30d_video_tags]
  end
end


# Find sites per plan

# for old plans
d = Time.utc(2012,1,1)
a = SitesTrend.where(d: d).first[:plans_count].inject({}) do |hash, (plan_id, c)|
  hash[Plan.find(plan_id).title] = c if plan_id.present?
  hash
end
puts "Date: #{d}"; puts a

# for new plans
SitesTrend.where(d: Time.utc(2011,12,1)).first[:pa]
