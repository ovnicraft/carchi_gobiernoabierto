# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :video do
    title_es {Faker::Lorem.sentence}
    title_eu {Faker::Lorem.sentence}
    title_en {Faker::Lorem.sentence}
    video_path "videos/"

    factory :published_video do
      published_at {1.day.ago}
    end
  end
end
