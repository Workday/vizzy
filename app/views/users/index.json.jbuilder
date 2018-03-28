json.array!(@users) do |user|
  json.extract! user, :id, :username, :role
  json.url user_url(user, format: :json)
end
