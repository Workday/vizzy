require 'test_helper'

class JenkinsPluginTest < ActiveSupport::TestCase

  def setup
    @unique_id = Rails.root.join('app', 'plugins', 'jenkins_plugin.rb').to_s.to_sym

    @build = FactoryBot.create(:build)
    @build.project = FactoryBot.create(:project)
    @build.save

    @jenkins_plugin = JenkinsPlugin.new(@unique_id)
    @project_settings_hash = @build.project.plugin_settings
  end

  test 'verify hook calls update description' do
    mock = MiniTest::Mock.new
    mock.expect(:update_display_name_and_description, {success: 'Ok'}, [@build])
    @jenkins_plugin.build_created_hook(@build)
    assert_send([mock, :update_display_name_and_description, @build])
  end

  test 'jenkins plugin loaded correctly' do
    plugin_manager = PluginManager.instance.for_project(@build.project)
    assert_not_nil(plugin_manager.plugins_hash[@unique_id])
  end

  test 'jenkins plugin disabled' do
    assert_equal(false, @project_settings_hash[@jenkins_plugin.unique_id][:enabled])
  end
end