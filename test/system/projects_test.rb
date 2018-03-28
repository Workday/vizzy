require 'application_system_test_case'
require 'test_helper'

class ProjectsTest < ApplicationSystemTestCase
  test 'login, create project, view user' do
    WebMock.allow_net_connect!
    clear_database

    visit root_path
    assert page.must_have_content('Log In')
    login

    assert page.must_have_content('Signed in successfully.')
    assert page.must_have_content('Projects')
    create_project
    assert page.must_have_content('Project was successfully created.')

    run_test_build('develop_1')
    run_test_build('pull_request_2')
    visit project_path(1)

    assert page.must_have_content('A Testing Plan')
    assert page.must_have_content('Latest Pull Requests')
    assert page.must_have_content('Latest Builds')
    assert page.must_have_button('Current Base Images')
    assert page.must_have_content('MOBILEANDROID-1840_ClearImageCacheOnLogout')
    assert page.must_have_content('ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740')

    click_on('Current Base Images')
    assert page.must_have_content('Base Images')
    assert page.must_have_content('light_colors')
    assert page.must_have_content('000000')
    assert page.must_have_content('000001')
    assert page.must_have_content('000002')
    click_on('000002')

    assert page.must_have_content('Test Details')
    assert page.must_have_content('Name: 000002')
    assert page.must_have_content('Current Base Image')
    assert page.must_have_content('ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740')
    assert page.must_have_content('Parent Test: light_colors')

    visit users_path
    assert page.must_have_content('Users')
    assert page.must_have_content('Username')
    assert page.must_have_content('Email')
    assert page.must_have_content('Role')
    click_link('Admin')
    assert page.must_have_content('User Info')
    assert page.must_have_content('Email: john.doe@gmail.com')
    assert page.must_have_content('Role: Admin')
  end
end