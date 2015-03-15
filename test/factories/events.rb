# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    title_es {Faker::Lorem.sentence}
    starts_at {3.hours.ago}
    ends_at {1.hour.from_now}
    association :organization, factory: :department

    factory :published_event do
      published_at {1.day.ago}
    end
  end
end
