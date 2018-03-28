require 'test_helper'

class TestTest < ActiveSupport::TestCase

  setup do
    @test = FactoryBot.create(:test)
  end

  test 'test is valid after creation' do
    assert @test.valid?
  end

  test 'test is populated correctly' do
    assert_equal 'Initial', @test.name, 'name not populated correctly'
    assert_equal 'First photo of the landing page', @test.description, 'description not populated correctly'
  end
end
