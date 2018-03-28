require 'test_helper'
require 'digest/md5'

class ImageTest < ActiveSupport::TestCase

  setup do
    @test_image = FactoryBot.create(:test_image)
  end

  test 'test image is valid after creation' do
    assert @test_image.valid?
  end

  test 'test image is populated correctly' do
    assert_equal '000000.png', @test_image.image_file_name, 'image_file_name not populated correctly'
    assert_equal false, @test_image.approved, 'approved not populated correctly'
    assert_equal 1, @test_image.build_id, 'build_id not populated correctly'
    assert_equal 2, @test_image.test_id, 'test_id not populated correctly'
  end
end
