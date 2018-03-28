require 'application_system_test_case'
require 'test_helper'

class BuildsTest < ApplicationSystemTestCase
  test 'develop 1, pr 1 should cause no diffs' do
    initialize_build_test

    run_test_build('develop_1')

    visit_last_created_build
    assert_images_checked(7)
    assert_differences_found(0)
    assert_new_tests(7)
    assert_no_visual_differences_found

    run_test_build('pull_request_1')

    visit_last_created_build
    take_screenshot
    assert_images_checked(7)
    assert_differences_found(0)
    assert_new_tests(0)
    assert_successful_tests(7)
  end

  test 'develop 1, pr 2, pr 2, pr 3 should cause diffs' do
    initialize_build_test

    run_test_build('develop_1')
    run_test_build('pull_request_2')

    visit_last_created_build
    assert_images_checked(7)
    assert_differences_found(7)
    assert_new_tests(0)

    open_first_unapproved_diff
    assert_diffs_page_has_all_content

    approve_current_diff
    click_button('Next')
    approve_current_diff
    approve_current_diff

    # verify that fields on diff page work correctly
    fill_in('test_comment', with: 'Here is a test comment.')
    fill_in('test_jira', with: "#{SystemTestConfig.jira_base_url}/browse/MOBILEANDROID-1234")
    fill_in('test_pull_request_link', with: "#{SystemTestConfig.github_root_url}/mobile/android/pulls/2")
    click_button('Save')
    visit_last_created_build
    page.must_have_content('Here is a test comment.')
    page.must_have_content("#{SystemTestConfig.jira_base_url}/browse/MOBILEANDROID-1234")
    page.must_have_content("#{SystemTestConfig.github_root_url}/mobile/android/pulls/2")

    # Assert that running the same pr build again gives same state as you left it
    run_test_build('pull_request_2')
    visit_last_created_build
    assert_images_checked(7)
    assert_differences_found(7)
    assert_new_tests(0)
    assert_diffs_approved(3)
    assert_diffs_waiting_for_approval(4)

    # Assert PR 3 is unrelated to PR 2
    # Note that it only uploads 6 images instead of 7
    run_test_build('pull_request_3')
    visit_last_created_build
    assert_images_checked(6)
    assert_differences_found(6)
    assert_new_tests(0)
    assert_missing_tests(1)
  end

  test 'develop 1, pr 2, develop 2 performs preapproval' do
    initialize_build_test

    run_test_build('develop_1')
    run_preapproval_pull_request('pull_request_2')

    visit_last_created_build
    open_first_unapproved_diff
    approve_current_diff
    approve_current_diff
    approve_current_diff

    run_preapproval_develop('develop_2')
    visit_last_created_build
    assert_images_checked(7)
    assert_differences_found(4)
    assert_new_tests(0)
    assert_successful_tests(3)
    assert_diffs_waiting_for_approval(4)
  end

  test 'develop 1, pr 2, pr3, develop 2 performs multiple preapproval' do
    initialize_build_test
    run_test_build('develop_1')

    run_preapproval_pull_request('pull_request_2')
    visit_last_created_build
    approve_all_diffs

    run_preapproval_pull_request('pull_request_3')
    visit_last_created_build
    approve_all_diffs

    run_preapproval_develop('develop_2')
    visit_last_created_build
    assert_images_checked(7)
    assert_differences_found(12)
    assert_new_tests(0)
    assert_successful_tests(1)
    assert_diffs_waiting_for_approval(12)
    open_first_unapproved_diff

    # multiple preapproval diff page
    page.must_have_button('Approve This Old Image')
    page.must_have_content('Old Image Pre-Approved By:')
    page.must_have_content('User: john.doe')
    page.must_have_content("Pull Request: #{SystemTestConfig.github_root_url}/mobile/android/pull/2")
    page.must_have_content("Pull Request: #{SystemTestConfig.github_root_url}/mobile/android/pull/3")

    approve_current_diff
    approve_current_diff

    run_preapproval_develop('develop_2')
    visit_last_created_build
    assert_images_checked(7)
    assert_differences_found(8)
    assert_new_tests(0)
    assert_successful_tests(3)
    assert_diffs_waiting_for_approval(8)
  end
end
