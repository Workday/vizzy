require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  setup do
    @project = FactoryBot.create(:project)
  end

  test 'project is valid after creation' do
    assert @project.valid?
  end

  test 'project is populated correctly' do
    assert_equal 'Testing', @project.name, 'name not populated correctly'
    assert_equal 'A Testing Plan', @project.description, 'description not populated correctly'
    assert_equal SystemTestConfig.github_root_url, @project.github_root_url, 'github_root_url not populated correctly'
    assert_equal SystemTestConfig.github_repo, @project.github_repo, 'github_repo not populated correctly'
    assert_equal 'continuous-integration/vizzy', @project.github_status_context, 'github_status_context not populated correctly'
  end
end
