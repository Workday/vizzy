require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    # Must be admin to destroy project
    sign_in with_test_user
    @project = FactoryBot.create(:project)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create project' do
    assert_difference('Project.count') do
      post :create, params: { project: { name: @project.name, description: @project.description }, authenticity_token: set_form_authenticity_token }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  test 'should update project' do
    patch :update, params: { id: @project, project: { name: @project.name }, authenticity_token:  set_form_authenticity_token }
    assert_redirected_to project_path(assigns(:project))
  end

  test 'should destroy project' do
    assert_difference('Project.count', -1) do
      delete :destroy, params: { id: @project, authenticity_token: set_form_authenticity_token  }
    end

    assert_redirected_to projects_path
  end
end
