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

  describe ".set_billing_name_from_name" do
    context "user has name" do
      subject { Factory.create(:user, name: 'Remy Coutable', billing_name: nil) }

      it "sets billing_name from name" do
        subject.billing_name.should be_nil

        described_class.set_billing_name_from_name

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

        described_class.set_billing_name_from_name

        subject.reload.billing_name.should be_nil
      end
    end
  end

end
