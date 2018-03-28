json.array!(@test_images) do |test_image|
  json.extract! test_image, :id, :test_id, :build_id, :approved, :test
end
