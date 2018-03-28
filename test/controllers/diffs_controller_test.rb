require 'test_helper'

class DiffsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    sign_in with_test_user
    @diff = FactoryBot.create(:diff)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create build' do
    assert_difference('Diff.count') do
      post :create, params: { diff: { old_image_id: @diff.old_image_id, new_image_id: @diff.new_image_id, build_id: @diff.build_id }, authenticity_token: set_form_authenticity_token }
    end

    assert_redirected_to diff_path(assigns(:diff))
  end

  test 'should update diff' do
    patch :update, params: {id: @diff, diff: { old_image_id: @diff.old_image_id, new_image_id: @diff.new_image_id }, authenticity_token: set_form_authenticity_token }
    assert_redirected_to diff_path(assigns(:diff))
  end


  test 'should destroy diff' do
    assert_difference('Diff.count', -1) do
      delete :destroy, params: { id: @diff, authenticity_token: set_form_authenticity_token }
    end
    assert_redirected_to diffs_path
  end
end
