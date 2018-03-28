require 'test_helper'

class JiraPluginTest < ActiveSupport::TestCase

  def setup
    @unique_id = Rails.root.join('app', 'plugins', 'jira_plugin.rb').to_s.to_sym

    @build = FactoryBot.create(:build)
    @build.project = FactoryBot.create(:project)
    @build.save

    @jira = FactoryBot.create(:jira)

    @jira_plugin = JiraPlugin.new(@unique_id)
    @jira_plugin.add_plugin_settings_to_project(@build.project)

    @project_settings_hash = @build.project.plugin_settings
  end

  test 'jira base url has value' do
    assert_equal(SystemTestConfig.jira_base_url, @project_settings_hash[@jira_plugin.unique_id][:jira_base_url][:value])
  end

  test 'jira project has value' do
    assert_equal(SystemTestConfig.jira_project, @project_settings_hash[@jira_plugin.unique_id][:jira_project][:value])
  end

  test 'jira component has value' do
    assert_equal('Visual Automation', @project_settings_hash[@jira_plugin.unique_id][:jira_component][:value])
  end

  test 'jira plugin loaded correctly' do
    plugin_manager = PluginManager.instance.for_project(@build.project)
    assert_not_nil(plugin_manager.plugins_hash[@unique_id])
  end

  test 'jira plugin credentials are present' do
    assert_not_empty(Rails.application.secrets.JIRA_USERNAME)
    assert_not_empty(Rails.application.secrets.JIRA_PASSWORD)
  end
end