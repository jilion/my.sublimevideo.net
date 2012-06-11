# coding: utf-8
require 'spec_helper'

describe EmailUniquenessValidator do
  let(:user) { create(:user, email: "john@doe.com") }

  context "on create" do
    it "should check uniqueness" do
      user2 = build(:user)
      validate_email_uniqueness(user2, :email, user.email)
      user2.errors[:email].should have(1).item
    end

    it "should compare case insensitive" do
      user2 = build(:user)
      validate_email_uniqueness(user2, :email, user.email.upcase)
      user2.errors[:email].should have(1).item
    end

    it "should ignore archived user" do
      user.reload.update_attribute(:state, 'archived')
      user = build(:user)
      validate_email_uniqueness(user, :email, user.email)
      user.errors.should be_empty
    end
  end

  context "on update" do
    subject { create(:user) }

    it "should check uniqueness not including himself" do
      validate_email_uniqueness(user, :email, user.email)
      user.errors.should be_empty
    end

    it "should check uniqueness" do
      user2 = create(:user, email: "john2@doe.com")
      validate_email_uniqueness(user2, :email, user.email)
      user2.errors[:email].should have(1).item
    end

    it "should compare case insensitive" do
      user2 = create(:user, email: "john2@doe.com")
      validate_email_uniqueness(user2, :email, user.email.upcase)
      user2.errors[:email].should have(1).item
    end

    it "should ignore archived user" do
      user.reload.update_attribute(:state, 'archived')
      user = create(:user, email: "john2@doe.com")
      validate_email_uniqueness(user, :email, user.email)
      user.errors.should be_empty
    end
  end
end

def validate_email_uniqueness(record, attribute, value)
  EmailUniquenessValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
