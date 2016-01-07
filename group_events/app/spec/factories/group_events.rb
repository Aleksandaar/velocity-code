FactoryGirl.define do
  factory :group_event do
    name "EventName"
    description "Description"
    location "New York"
    start_date { Date.current }
    end_date { Date.current + 30.days }
    duration 30
    status 0
  end
end
