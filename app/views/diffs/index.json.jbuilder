json.array!(@diffs) do |diff|
  json.extract! diff, :id, :old_image_id, :new_image_id
  json.diff_url diff_url(diff)
  json.build_url build_url(diff.build)
end

