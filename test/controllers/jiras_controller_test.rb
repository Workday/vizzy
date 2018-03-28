require 'test_helper'

class JirasControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    sign_in with_test_user
    @jira = FactoryBot.create(:jira)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:jiras)
  end

  test 'should get new' do
    get :new, params: { jira: { title: @jira.title } }
    assert_response :success
  end

  test 'should create jira' do
    hash = { success: SystemTestConfig.jira_base_url}
    @controller.stub(:create_jira, hash) do
      assert_difference('Jira.count') do
        post :create, params: {jira: {title: @jira.title, jira_link: @jira.jira_link}, authenticity_token: set_form_authenticity_token }
      end
    end

    assert_redirected_to @jira.jira_link
  end

  test 'should show jira' do
    get :show, params: { id: @jira }
    assert_response :success
  end

  test 'should update jira' do
    hash = { success: SystemTestConfig.jira_base_url}
    @controller.stub(:create_jira, hash) do
      patch :update, params: {id: @jira, jira: {title: @jira.title}, authenticity_token: set_form_authenticity_token }
    end
    assert_redirected_to @jira.jira_link
  end

  test 'should destroy jira' do
    assert_difference('Jira.count', -1) do
      delete :destroy, params: { id: @jira, authenticity_token: set_form_authenticity_token }
    end

    assert_redirected_to jiras_path
  end
end
