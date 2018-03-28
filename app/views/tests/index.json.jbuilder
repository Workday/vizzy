json.array!(@tests) do |test|
  json.extract! test, :id, :name, :description, :test_suite_id
  json.url test_url(test, format: :json)
end
