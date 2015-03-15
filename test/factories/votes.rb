# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :vote do
    association :user, factory: :person

    factory :proposal_vote do
      association :votable, factory: :published_and_approved_proposal

      factory :positive_proposal_vote do
        positive
      end

      factory :negative_proposal_vote do
        negative
      end

    end

    # factory :debate_argument should have same attributes

    trait :positive do
      value 1
    end

    trait :negative do
      value -1
    end

  end
end
