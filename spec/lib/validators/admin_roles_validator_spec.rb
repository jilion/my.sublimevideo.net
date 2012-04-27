# coding: utf-8
require 'spec_helper'

describe AdminRolesValidator do
  subject { build(:admin) }

  describe "empty roles 1" do
    it "should not add an error" do
      validate_admin_roles(subject, :roles, [])
      subject.errors[:roles].should be_empty
    end
  end

  describe "empty roles 2" do
    it "should not add an error" do
      validate_admin_roles(subject, :roles, [''])
      subject.errors[:roles].should be_empty
    end
  end

  describe "valid admin roles" do
    it "should not add an error" do
      validate_admin_roles(subject, :roles, AdminRole.roles)
      subject.errors[:roles].should be_empty
    end
  end

  describe "roles that include undefined roles" do
    it "should add an error" do
      validate_admin_roles(subject, :roles, ['foo'])
      subject.errors[:roles].should have(1).item
    end
  end

  describe "duplicated roles" do
    it "should add an error" do
      validate_admin_roles(subject, :roles, [AdminRole.roles.first, AdminRole.roles.first])
      subject.errors[:roles].should have(1).item
    end
  end

end

def validate_admin_roles(record, attribute, value)
  AdminRolesValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
