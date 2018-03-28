json.extract! @build, :id, :dev_build, :commit_sha, :pull_request_number, :url, :temporary, :title, :created_at, :updated_at, :image_md5s
json.base_image_count @build.base_images.size