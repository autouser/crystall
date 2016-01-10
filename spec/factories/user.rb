FactoryGirl.define do

  factory :user do
    username "john"
    password "test1234"
  end

  factory :admin, class: User do
    username "admin"
    password "test1234"
    admin    true
  end

end