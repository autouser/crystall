FactoryGirl.define do

  factory :project do

    transient do
      n nil
    end
    
    name        { n ? "Project #{n}" : "Project" }
    description { n ? "Project Description #{n}" : "Project Description" }
    status      "open"

    user

  end

end