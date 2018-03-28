require 'test_helper'

class BambooPluginTest < ActiveSupport::TestCase

  def setup
    @unique_id = Rails.root.join('app', 'plugins', 'bamboo_plugin.rb').to_s.to_sym

    stub_request(:post, "#{SystemTestConfig.bamboo_base_url}/rest/api/latest/result/ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740/comment").
        to_return(status: 204)

    @build = FactoryBot.create(:build)
    @build.project = FactoryBot.create(:project)
    @build.save

    @bamboo_plugin = BambooPlugin.new(@unique_id)
    @bamboo_plugin.add_plugin_settings_to_project(@build.project)
  end

  test 'verify hook calls comment on build' do
    mock = MiniTest::Mock.new
    mock.expect(:comment_on_build, {success: 'Ok'}, [@build])
    @bamboo_plugin.build_created_hook(@build)
    assert_send([mock, :comment_on_build, @build])
  end

  test 'bamboo build url has value' do
    project_settings_hash = @build.project.plugin_settings
    assert_equal(SystemTestConfig.bamboo_base_url, project_settings_hash[@bamboo_plugin.unique_id][:base_bamboo_build_url][:value])
  end

  test 'bamboo plugin loaded correctly' do
    plugin_manager = PluginManager.instance.for_project(@build.project)
    assert_not_nil(plugin_manager.plugins_hash[@unique_id])
  end

  test 'bamboo plugin credentials are present' do
    assert_not_empty(Rails.application.secrets.BAMBOO_USERNAME)
    assert_not_empty(Rails.application.secrets.BAMBOO_PASSWORD)
  end
end