require 'test_helper'

class JiraTest < ActiveSupport::TestCase

  setup do
    @jira = FactoryBot.create(:jira)
  end

  test 'Jira is valid after creation' do
    assert @jira.valid?
  end

  test 'jira is populated correctly' do
    assert_equal 'Visual Automation Test Issue: LightColors_000000', @jira.title, 'title not populated correctly'
    assert_equal SystemTestConfig.jira_project, @jira.project, 'project not populated correctly'
    assert_equal 'Visual Automation', @jira.component, 'component not populated correctly'
    assert_equal 'https://vizzy.com/diffs/21839', @jira.description, 'description not populated correctly'
    assert_equal "#{SystemTestConfig.jira_base_url}/browse/MOBILEANDROID-13135", @jira.jira_link, 'jira_link not populated correctly'
    assert_equal 'Bug', @jira.issue_type, 'issue_type not populated correctly'
    assert_equal 'MOBILEANDROID-13135', @jira.jira_key, 'jira_key not populated correctly'
    assert_equal 1, @jira.diff_id, 'diff_id not populated correctly'
    assert_equal 'Critical', @jira.priority, 'priority not populated correctly'
  end
end

