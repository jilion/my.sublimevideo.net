require 'spec_helper'

feature "Hidable notices" do

  describe "notice 1: 'Checkout the v2 new features'" do
    background do
      sign_in_as :user
      @site = Factory.create(:site, user: @current_user)
    end

    context "user didn't hide the notice" do
      context "and has video views" do
        background do
          Factory.create(:site_stat, t: @site.token, d: 30.days.ago.midnight, pv: { e: 1 }, vv: { m: 2 })
          go 'my', '/sites'
        end

        scenario "notice is visible and hidable" do
          page.should have_css '#hidable_notice_1'

          within '#hidable_notice_1' do
            click_button 'close'
          end

          page.should have_no_css '#hidable_notice_1'
        end
      end

      context "and has no video views" do
        scenario "notice is not visible" do
          go 'my', '/sites'
          page.should have_no_css '#hidable_notice_1'
        end
      end
    end

    context "user did hide the notice" do
      background do
        @current_user.hidden_notice_ids = [1]
        @current_user.save
        @current_user.reload.hidden_notice_ids.should eq [1]
      end

      context "and has video views" do
        background do
          Factory.create(:site_stat, t: @site.token, d: 30.days.ago.midnight, pv: { e: 1 }, vv: { m: 2 })
          go 'my', '/sites'
        end

        scenario "notice is not visible" do
          page.should have_no_css '#hidable_notice_1'
        end
      end

      context "and has no video views" do
        scenario "notice is not visible" do
          go 'my', '/sites'
          page.should have_no_css '#hidable_notice_1'
        end
      end
    end
  end

  describe "notice 2: 'More infos incomplete'" do
    background do
      sign_in_as :user, company_name: 'Jilion', company_url: 'http://jilion.com', company_job_title: 'Foo', company_employees: 'foo'
      Factory.create(:site, user: @current_user)
    end

    context "user didn't hide the notice" do
      context "and has 'More infos' incomplete" do
        background do
          @current_user.billing_postal_code = ""
          @current_user.save
          @current_user.reload.should be_more_infos_incomplete
          go 'my', '/sites'
        end

        scenario "notice is visible and hidable" do
          page.should have_css '#hidable_notice_2'

          within '#hidable_notice_2' do
            click_button 'close'
          end

          page.should have_no_css '#hidable_notice_2'
        end
      end

      context "and has 'More infos' complete" do
        background do
          @current_user.should_not be_more_infos_incomplete
          go 'my', '/sites'
        end

        scenario "notice is not visible" do
          page.should have_no_css '#hidable_notice_2'
        end
      end
    end

    context "user did hide the notice" do
      background do
        @current_user.hidden_notice_ids = [2]
        @current_user.save
        @current_user.reload.hidden_notice_ids.should eq [2]
      end

      context "and has 'More infos' incomplete" do
        background do
          @current_user.billing_postal_code = ""
          @current_user.should be_more_infos_incomplete
          go 'my', '/sites'
        end

        scenario "notice is not visible" do
          page.should have_no_css '#hidable_notice_2'
        end
      end

      context "and has 'More infos' complete" do
        background do
          @current_user.should_not be_more_infos_incomplete
          go 'my', '/sites'
        end

        scenario "notice is not visible" do
          page.should have_no_css '#hidable_notice_2'
        end
      end
    end
  end

end
