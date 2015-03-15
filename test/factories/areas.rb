# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :area do
    name_es {Faker::Company.name}
    area_tag_name {"_a_" + Faker::Lorem.word}
  end
end
