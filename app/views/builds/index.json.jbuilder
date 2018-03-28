json.array!(@builds) do |build|
  json.extract! build, :id, :url, :temporary, :title
  json.url build_url(build, format: :json)
end
