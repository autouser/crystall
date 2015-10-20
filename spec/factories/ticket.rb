FactoryGirl.define do

  factory :ticket do
    
    subject "Ticket"
    content "Ticket Content"
    status  "open"

    user
    project

  end

end