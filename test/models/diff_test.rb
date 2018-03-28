require 'test_helper'

class DiffTest < ActiveSupport::TestCase
  setup do
    @diff = FactoryBot.create(:diff)
  end

  test 'diff is valid after creation' do
    assert @diff.valid?
  end

  test 'diff is populated correctly' do
    assert_equal 1, @diff.old_image_id, 'old_image_id not populated correctly'
    assert_equal 2, @diff.new_image_id, 'new_image_id not populated correctly'
    assert_equal 1, @diff.build_id, 'build_id not populated correctly'
  end
end
