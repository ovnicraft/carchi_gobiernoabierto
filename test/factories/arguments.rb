# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :argument do
    reason {Faker::Lorem.sentence}
    association :user, factory: :person

    factory :proposal_argument do
      association :argumentable, factory: :published_and_approved_proposal

      factory :in_favor_proposal_argument do
        in_favor
      end

      factory :against_proposal_argument do
        against
      end

      factory :published_in_favor_proposal_argument do
        published
        in_favor
      end
    end

    # factory :debate_argument should have same attributes

    trait :in_favor do
      value 1
    end

    trait :against do
      value -1
    end

    trait :published do
      published_at 1.hour.ago
    end
  end
end
