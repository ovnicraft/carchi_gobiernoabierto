# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :news do
    title_es {Faker::Lorem.sentence}
    association :organization

    factory :published_news do
      published_at 2.days.ago
    end
  end
end
