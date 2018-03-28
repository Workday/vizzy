require 'test_helper'

class TestImagesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    sign_in with_test_user
    @test_image = FactoryBot.create(:test_image)
    @test_image.build = FactoryBot.create(:build)
    @test_image.save
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:test_images)
  end

  test 'should destroy test_image' do
    assert_difference('TestImage.count', -1) do
      delete :destroy, params: { id: @test_image, authenticity_token: set_form_authenticity_token }
    end

    assert_redirected_to test_images_path
  end
end
