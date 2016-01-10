FactoryGirl.define do

  factory :project do
    name        "Project"
    description "Project Description"
    status      "open"

    user
  end

end