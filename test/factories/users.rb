FactoryBot.define do
  factory :user do
    email 'john.doe@gmail.com'
    username 'john.doe'
    password '123456789012'
    authentication_token 'ht2Cey1i9xbxH5jm-gpx'
    admin true
    initialize_with { User.find_or_create_by(email: email)}
  end
end