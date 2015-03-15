# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :proposal do
    title_es {Faker::Lorem.sentence}
    body_es {Faker::Lorem.sentence}
    association :department, factory: :organization
    area_tags {[FactoryGirl.create(:area).area_tag.name_es]}
    association :user, factory: :person

    factory :published_and_approved_proposal do
      published_at 2.days.ago
      status 'aprobado'
    end
  end
end
