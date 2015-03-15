# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    name_es {Faker::Company.name}

    factory :department, class: Department do
      tag_name {"_" + Faker::Lorem.word}
    end
  end
end
