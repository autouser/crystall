FactoryGirl.define do

  factory :user do
    username "john"
    password "test1234"

    factory :user_with_projects do
      
      transient do
        projects_count 1
      end

      after(:create) do |user, e|
        # create_list(:project, e.projects_count, user: user)
        ( 1 .. e.projects_count).each {|n| create :project, name: "#{user.username.capitalize} Project #{n}", user: user}
      end

    end

  end

  factory :admin, class: User do
    username "admin"
    password "test1234"
    admin    true


    factory :admin_with_projects do
      
      transient do
        projects_count 1
      end

      after(:create) do |user, e|
        # create_list(:project, e.projects_count, user: user)
        ( 1 .. e.projects_count).each {|n| create :project, name: "#{user.username.capitalize} Project #{n}", user: user}
      end

    end

  end

end