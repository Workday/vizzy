json.array!(@jiras) do |jira|
  json.extract! jira, :id
  json.url jira_url(jira, format: :json)
end
