Factory.define :user do |f|
  f.full_name               "Joe Blow"
  f.sequence(:email)        { |n| "email#{n}@user.com" }
  f.password                "123456"
end
