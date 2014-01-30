require 'spec_helper'

feature "Hidable notices" do

  describe "notice 2: 'More info incomplete'" do
    background do
      Timecop.travel(3.weeks.ago) do
        sign_in_as :user, company_name: 'Jilion', company_url: 'http://jilion.com', company_job_title: 'Foo', company_employees: 'foo'
        @site = build(:site, user: @current_user)
        SiteManager.new(@site).create
      end
    end

    context "user didn't hide the notice" do
      context "and has 'More info' incomplete" do
        background do
          @current_user.company_name = ""
          @current_user.save
          @current_user.reload.should be_more_info_incomplete
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

      context "and has 'More info' complete" do
        background do
          @current_user.should_not be_more_info_incomplete
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

      context "and has 'More info' incomplete" do
        background do
          @current_user.company_name = ""
          @current_user.should be_more_info_incomplete
          go 'my', '/sites'
        end

        scenario "notice is not visible" do
          page.should have_no_css '#hidable_notice_2'
        end
      end
    end
  end

end
