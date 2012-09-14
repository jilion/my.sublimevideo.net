class Member < ActiveRecord::Base
  has_one :current_membership
  has_one :selected_membership
  has_one :membership
  has_many :fellow_members, :through => :club, :source => :members
  has_one :club, :through => :current_membership
  has_one :selected_club, :through => :selected_membership, :source => :club
  has_one :favourite_club, :through => :membership, :conditions => ["memberships.favourite = ?", true], :source => :club
  has_one :hairy_club, :through => :membership, :conditions => {:clubs => {:name => "Moustache and Eyebrow Fancier Club"}}, :source => :club
  has_one :sponsor, :as => :sponsorable
  has_one :sponsor_club, :through => :sponsor
  has_one :member_detail
  has_one :organization, :through => :member_detail
  belongs_to :member_type

  has_many :nested_member_types, :through => :member_detail, :source => :member_type
  has_one :nested_member_type, :through => :member_detail, :source => :member_type

  has_many :nested_sponsors, :through => :sponsor_club, :source => :sponsor
  has_one :nested_sponsor, :through => :sponsor_club, :source => :sponsor

  has_many :organization_member_details, :through => :member_detail
  has_many :organization_member_details_2, :through => :organization, :source => :member_details

  has_one :club_category, :through => :club, :source => :category

  has_many :current_memberships
  has_one :club_through_many, :through => :current_memberships, :source => :club

  has_many :current_memberships, :conditions => { :favourite => true }
  has_many :clubs, :through => :current_memberships
end
