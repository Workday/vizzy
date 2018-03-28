require 'application_system_test_case'
require 'test_helper'

class JirasTest < ApplicationSystemTestCase
  test "create jira from diff" do
    initialize_build_test

    run_test_build('develop_1')
    run_test_build('pull_request_2')
    visit_last_created_build
    open_first_unapproved_diff
    click_on('Create Jira')

    page.must_have_content('New Jira')
    page.must_have_content('Project')
    page.must_have_content('Jira Title')
    page.must_have_content('Component')
    page.must_have_content('Issue Type')
    page.must_have_content('Priority')
    page.must_have_content('Description')
    page.must_have_content('Images attached')
    page.must_have_button('Create Jira')

    click_on('Create Jira')
    page.must_have_content('Creating issues is turned off')
  end
end
