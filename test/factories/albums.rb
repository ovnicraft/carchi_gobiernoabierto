# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :album do
    title_es {Faker::Lorem.sentence}

    factory :published_album do
      draft {false}
    end
  end
end
