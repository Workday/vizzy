require 'test_helper'

class BuildsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    sign_in with_test_user
    @build = FactoryBot.create(:build)
    @build.project = FactoryBot.create(:project)
    image_md5s_hash = {}
    image_md5s_hash['AddAndMoveGridRows/AddAndMoveGridRows_01_InitialGridView'] = '12c755932dad470548c5c47708101e3d'
    image_md5s_hash['AddAndMoveGridRows/AddAndMoveGridRows_02_ActionsModeOpen'] = '18b6543d01070e5502c1d90d9227d8ca'
    @build.full_list_of_image_md5s = image_md5s_hash
    @build.save
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:builds)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create build' do
    pr_response = {
        "user": {
            "ldap_dn": "CN=john.doe,OU=Users,OU=domain,DC=domaininternal,DC=com"
        },
        "head": {
            "ref": "MOBILEANDROID-4659_FakeBranchToTestPullRequest"
        }
    }

    stub_request(:post, "#{SystemTestConfig.bamboo_base_url}/rest/api/latest/result/ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740/comment").
        to_return(status: 200, body: "", headers: {})

    stub_request(:get, "#{SystemTestConfig.github_root_url}/api/v3/repos/mobile/android/pulls/1704").
        to_return(body: pr_response.to_json)

    stub_request(:post, "#{SystemTestConfig.github_root_url}/api/v3/repos/mobile/android/statuses/d3e552976815db44ac05983a817f7d1c333ef98e").
        to_return(status: 200, body: "", headers: {})

    assert_difference('Build.count') do
      post :create, format: :json, params: {build: {title: @build.title, url: @build.title, project_id: @build.project_id, temporary: @build.temporary, commit_sha: @build.commit_sha,
                                                    pull_request_number: @build.pull_request_number, image_md5s: @build.image_md5s}}
    end

    assert_response :created
  end

  test 'should update build' do
    patch :update, params: { id: @build, build: { title: @build.title, url: @build.url }, authenticity_token: set_form_authenticity_token }
    assert_redirected_to build_path(assigns(:build))
  end

  test 'should destroy build' do
    assert_difference('Build.count', -1) do
      delete :destroy, params: { id: @build, authenticity_token: set_form_authenticity_token }
    end
    assert_redirected_to builds_path
  end
end
