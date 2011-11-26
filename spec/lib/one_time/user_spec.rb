# coding: utf-8
require 'spec_helper'

describe OneTime::User do

  describe ".set_name_from_first_and_last_name" do
    context "user is active / has first & last name" do
      subject { Factory.create(:user, first_name: 'Remy', last_name: 'Coutable') }

      it "sets name to first_name + ' ' + last_name" do
        subject.name = nil
        subject.save!(validate: false)

        subject.name.should be_nil

        described_class.set_name_from_first_and_last_name

        subject.reload.name.should eq 'Remy Coutable'
      end
    end

    context "user has no first & last name" do
      subject { Factory.create(:user, first_name: nil, last_name: nil) }

      it "sets name to first_name + ' ' + last_name" do
        subject.name = nil
        subject.save!(validate: false)

        subject.name.should be_nil

        described_class.set_name_from_first_and_last_name

        subject.reload.name.should be_nil
      end
    end
  end

  describe ".set_billing_info" do
    context "user has name" do
      subject { Factory.create(:user, name: 'Remy Coutable', billing_name: nil) }

      it "sets billing_name from name" do
        subject.billing_name.should be_nil

        described_class.set_billing_info

        subject.reload.billing_name.should eq 'Remy Coutable'
      end
    end

    context "user has no name" do
      subject do
        user = Factory.create(:user, billing_name: nil)
        user.name = nil
        user.save!(validate: false)
        user
      end

      it "doesn't set billing_name" do
        subject.billing_name.should be_nil

        described_class.set_billing_info

        subject.reload.billing_name.should be_nil
      end
    end

    context "user has no billing_postal_code" do
      subject { Factory.create(:user, billing_postal_code: nil, postal_code: '1234') }

      it "doesn't set billing_name" do
        subject.billing_postal_code.should be_nil

        described_class.set_billing_info

        subject.reload.billing_postal_code.should eq '1234'
      end
    end

    context "user has a billing_postal_code code" do
      subject { Factory.create(:user, billing_postal_code: '91470', postal_code: '1234') }

      it "doesn't set billing_name" do
        subject.billing_postal_code.should eq '91470'

        described_class.set_billing_info

        subject.reload.billing_postal_code.should eq '91470'
      end
    end

    context "user has no billing_country" do
      subject { Factory.create(:user, billing_country: nil, country: 'FR') }

      it "doesn't set billing_name" do
        subject.billing_country.should be_nil

        described_class.set_billing_info

        subject.reload.billing_country.should eq 'FR'
      end
    end

    context "user has a billing_country" do
      subject { Factory.create(:user, billing_country: 'CH', country: 'FR') }

      it "doesn't set billing_name" do
        subject.billing_country.should eq 'CH'

        described_class.set_billing_info

        subject.reload.billing_country.should eq 'CH'
      end
    end
  end

end
