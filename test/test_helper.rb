require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails/capybara'
require 'rake'
require 'webmock/minitest'
require 'minitest/mock'

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_SYSTEM_TESTING_SCREENSHOT'] = 'simple'

Rake::Task.clear # necessary to avoid tasks being loaded several times in dev mode
VisualAutomation::Application.load_tasks # load rake tasks

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Add more helper methods to be used by all tests here...

  # -------- Generic helper methods -------- #

  def login
    user = with_test_user
    fill_in('Email', with: user.email)
    fill_in('Password', with: user.password)
    click_button('Log In')
  end

  def with_test_user
    # test user must be an admin for all tests to pass
    user = User.find_by_email('john.doe@gmail.com')
    if user.nil?
      puts "User john.doe@gmail.com does not exist, creating new user"
    end
    user = user.nil? ? FactoryBot.create(:user) : user
    puts "User auth token: #{user.authentication_token}, email: #{user.email}, admin: #{user.admin}"
    user
  end

  # -------- Project helper methods -------- #

  def create_project
    click_on('New Project')
    find("input[id$='project_name']").set 'Testing'
    find("input[id$='project_description']").set 'A Testing Plan'
    find("input[id$='project_github_root_url']").set SystemTestConfig.github_root_url
    find("input[id$='project_github_repo']").set SystemTestConfig.github_repo
    find("input[id$='project_github_status_context']").set 'continuous-integration/vizzy'

    # plugin settings
    jira_input_id = get_input_id_for_plugin('jira_plugin.rb')
    find("input[id='#{jira_input_id}_jira_project_value']").set SystemTestConfig.jira_project
    find("input[id='#{jira_input_id}_jira_base_url_value']").set SystemTestConfig.jira_base_url
    find("input[id='#{get_input_id_for_plugin('bamboo_plugin.rb')}_base_bamboo_build_url_value']").set SystemTestConfig.bamboo_base_url
    find("input[id='#{get_input_id_for_plugin('slack_plugin.rb')}_slack_channel_value']").set 'test_channel'

    click_on('Submit')
  end

  def get_input_id_for_plugin(plugin)
    rails_root_join = Rails.root.join('app', 'plugins', plugin).to_s.gsub('/', '_')
    "plugin_settings_#{rails_root_join}"
  end

  # -------- Build helper methods -------- #

  def initialize_build_test
    WebMock.allow_net_connect!

    clear_database

    visit projects_path
    login
    FactoryBot.create(:project)
  end

  def clear_database
    # clear the database with the current schema
    system("rails db:environment:set RAILS_ENV=#{ENV['RAILS_ENV']}")
    system('rake db:schema:load')
  end

  def run_test_build(build_ref)
    rake_task, uri_with_port = get_build_params_and_reenable_rake_task(build_ref)
    Rake.application[rake_task].invoke(uri_with_port)
  end

  def run_preapproval_pull_request(build_ref)
    rake_task, uri_with_port = get_build_params_and_reenable_rake_task(build_ref)
    pull_request_number = build_ref.rpartition('_').last.to_i
    pull_request_preapproval_git_sha = github_recent_commits[pull_request_number]
    Rake.application[rake_task].invoke(uri_with_port, pull_request_preapproval_git_sha, pull_request_number)
  end

  def run_preapproval_develop(build_ref)
    rake_task, uri_with_port = get_build_params_and_reenable_rake_task(build_ref)
    develop_most_recent_sha = github_recent_commits.first
    Rake.application[rake_task].invoke(uri_with_port, develop_most_recent_sha)
  end

  def visit_last_created_build
    id = get_build_id
    puts "Visiting build with id: #{id}"
    visit build_path(id)
  end

  def assert_diffs_page_has_all_content
    page.must_have_button('Approve New Image')
    page.must_have_button('Create Jira')
    page.must_have_button('Next')
    page.must_have_button('Base Images for Test')
    page.must_have_button('Test History')
    page.must_have_button('Save')
    page.must_have_content('Jira')
    page.must_have_content('Pull Request')
    page.must_have_content('Comment')
  end

  def assert_successful_tests(number)
    page.must_have_content("#{number} successful test(s)")
  end

  def assert_images_checked(number)
    page.must_have_content("#{number} images checked")
  end

  def assert_differences_found(number)
    page.must_have_content("#{number} difference(s) found")
  end

  def assert_new_tests(number)
    page.must_have_content("#{number} new test(s) added")
  end

  def assert_missing_tests(number)
    page.must_have_content("#{number} missing test(s)")
  end

  def assert_no_visual_differences_found
    page.must_have_content 'No visual differences were found between this build and the base images.'
  end

  def assert_diffs_waiting_for_approval(number)
    page.must_have_content("#{number} diffs waiting for approval")
  end

  def assert_diffs_approved(number)
    page.must_have_content("#{number} diffs approved")
  end

  def open_first_unapproved_diff
    build = Build.find(get_build_id)
    first_diff = build.unapproved_diffs.first
    visit diff_path(first_diff.id)
  end

  def approve_current_diff
    click_button('Approve New Image')
  end

  def approve_all_diffs
    click_button('Approve All Images')
  end

  private
  def get_build_id
    temp_build_file = File.read(Rails.root.join('test-image-upload', 'tmp-buildfile'))
    data = JSON.parse(temp_build_file)
    data['id']
  end

  def get_build_params_and_reenable_rake_task(build_ref)
    current_url = URI.parse(page.current_url)
    uri_with_port = "http://#{current_url.host}:#{current_url.port}"
    rake_task = "run_test_build:#{build_ref}"
    Rake.application[rake_task].reenable
    [rake_task, uri_with_port]
  end

  def github_recent_commits
    associated_git_shas = []
    GithubService.run(Project.find(1).github_root_url, Project.find(1).github_repo) do |service|
      associated_git_shas = service.most_recent_github_commits
    end
    associated_git_shas
  end

  def set_form_authenticity_token
    session[:_csrf_token] = SecureRandom.base64(32)
  end
end
