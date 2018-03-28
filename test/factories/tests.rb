FactoryBot.define do
  factory :test do
    name 'Initial'
    description 'First photo of the landing page'
    association :project_id, factory: :project
  end
end
