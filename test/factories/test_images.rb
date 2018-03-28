FactoryBot.define do
  factory :test_image do
    image_file_name '000000.png'
    approved false
    build_id 1
    test_id 2
    md5 '5d06899520fdbe8fccf6e83eb33998d0'
    image { File.new(Rails.root.join('test-image-upload/image_set1/dark_colors/000000.png')) }
  end
end
