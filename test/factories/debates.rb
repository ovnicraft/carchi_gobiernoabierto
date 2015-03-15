# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :debate do
    title_es {Faker::Lorem.sentence}
    association :department
    hashtag {"#"+Faker::Lorem.word}
    multimedia_dir "dir_debate"



    factory :published_debate do
      published_at 2.days.ago
      # ignore do
      #   stages_count 1
      # end
      after(:build) do |debate, evaluator|
        # create_list(:debate_stage, evaluator.stages_count, debate: debate) # not working (?)
        debate.stages << FactoryGirl.build(:debate_stage, debate: debate)
      end
    end


  end

  factory :debate_stage do
    starts_on {2.days.ago}
    ends_on {2.days.from_now}
    label "presentation"
  end
end
