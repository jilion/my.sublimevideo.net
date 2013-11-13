# coding: utf-8
require 'spec_helper'

describe AdminRolesValidator do
  let(:admin) { Admin.new }

  describe "empty roles 1" do
    it "should not add an error" do
      validate_admin_roles(admin, :roles, [])
      expect(admin.errors[:roles]).to be_empty
    end
  end

  describe "empty roles 2" do
    it "should not add an error" do
      validate_admin_roles(admin, :roles, [''])
      expect(admin.errors[:roles]).to be_empty
    end
  end

  describe "valid admin roles" do
    it "should not add an error" do
      validate_admin_roles(admin, :roles, Admin.roles)
      expect(admin.errors[:roles]).to be_empty
    end
  end

  describe "roles that include undefined roles" do
    it "should add an error" do
      validate_admin_roles(admin, :roles, ['foo'])
      expect(admin.errors[:roles].size).to eq(1)
    end
  end

  describe "duplicated roles" do
    it "should add an error" do
      validate_admin_roles(admin, :roles, [Admin.roles.first, Admin.roles.first])
      expect(admin.errors[:roles].size).to eq(1)
    end
  end

end

def validate_admin_roles(record, attribute, value)
  AdminRolesValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
