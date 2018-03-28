require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = with_test_user
    sign_in @user
  end

  test 'should get index user' do
    get users_path
    assert_response :success
  end

  test 'should get show user' do
    get user_path(id: @user.id)
    assert_response :success
  end
end
