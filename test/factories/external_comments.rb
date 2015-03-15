# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :external_comments_item, class: ExternalComments::Item do
    association :irekia_news, factory: :published_news
    association :client, factory: :external_comments_client
    url {Faker::Internet.url}
  end

  factory :external_comments_client, class: ExternalComments::Client do
    name {Faker::Company.name}
    code {Faker::Code.isbn}
    url {Faker::Internet.url}
    association :organization, factory: :department
  end
end
