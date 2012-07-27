# for each cohort, per month
#   - # of sites in each plan
#   - $$ of revenue per plan
#   - # of users in each 'usage state'
#   - # of sites per user
#   - # of videos per user
#   - # of plays per user
#
# Usage states are:
#   - signed_up
#   - active (not archived)
#   (- confirmed) => we could remove this state
#   - with_site (has at least 1 site active)
#   - test_config (has at least 1 video load ever)
#   - test_usage (has at least 1 video play ever)
#   - usage (has at least 50 video plays ever)
#   - recent_usage (has at least 50 video plays in the last 90 days)
#   - last_month_usage (has at least 50 video plays in the last 30 days)
class MonthlyBusinessReport
  include Mongoid::Document

  field :d, type: Hash, default: {} # Report dates: { cm (cohort month) => Datetime, rm (report month) => Datetime }

  field :u, type: Hash, default: {} # Per user { us (usage state) => { su (signed-up) => 200,
                                    #                                  ac (active) => 150,
                                    #                                  ws (with site) => 140,
                                    #                                  tc (test config) => 100,
                                    #                                  tc (test usage) => 80,
                                    #                                  us (usage) => 50,
                                    #                                  ru (recent usage) => 20,
                                    #                                  lu (last month usage) => 18 },
                                    #            s (sites) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #            v (videos) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #            p (plays) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #            rp (last 30 days plays) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 } }

  field :p, type: Hash, default: {} # Per plan { free => { c (count) => 2000,
                                    #                      v (videos) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #                      p (plays) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #                      rp (last 30 days plays) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 } },
                                    #            plus => { c (count) => 1000,
                                    #                      r (revenue) => 2000,
                                    #                      v (videos) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #                      p (plays) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 },
                                    #                      rp (last 30 days plays) => { '0' => 1200, '1' => 500, '2' => 250, '3-10' => 100, '10+' => 5 } } }

  index :d

end
