require 'test_helper'

class TestsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    sign_in with_test_user
    @test = FactoryBot.create(:test)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create test" do
    assert_difference('Test.count') do
      post :create, params: { test: { name: @test.name, description:  @test.description }, authenticity_token: set_form_authenticity_token }
    end
    assert_redirected_to test_path(assigns(:test))
  end

  test "should destroy test" do
    assert_difference('Test.count', -1) do
      delete :destroy, params: { id: @test, authenticity_token: set_form_authenticity_token }
    end
    assert_redirected_to tests_path
  end
end
