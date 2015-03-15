# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :comment do
    body {Faker::Lorem.sentence}
    association :user, factory: :person

    factory :comment_on_proposal do
      association :commentable, factory: :published_and_approved_proposal

      factory :official_comment_on_proposal do
        official
      end
    end

    factory :comment_on_news do
      association :commentable, factory: :published_news

      factory :official_comment_on_news do
        official
      end
    end

    factory :comment_on_event do
      association :commentable, factory: :published_event

      factory :official_comment_on_event do
        official
      end
    end

    factory :comment_on_video do
      association :commentable, factory: :published_video

      factory :official_comment_on_video do
        official
      end
    end

    factory :comment_on_external_item do
      association :commentable, factory: :external_comments_item
      factory :official_comment_on_external_item do
        official
      end
    end

    factory :comment_on_debate do
      association :commentable, factory: :published_debate

      factory :official_comment_on_debate do
        official
      end
    end

    trait :official do
      association :user, factory: :department_editor
    end
  end
end
