# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email {Faker::Internet.email}
    name {Faker::Name.name}
    password {Faker::Internet.password}
    password_confirmation { |u| u.password }

    factory :person, class: 'Person' do
      type 'Person'
    end

    factory :admin, class: 'Admin' do
      type 'Admin'
    end

    factory :department_editor, class: 'DepartmentEditor' do
      type 'DepartmentEditor'
      association :organization
    end
  end
end
