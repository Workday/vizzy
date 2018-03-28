require 'test_helper'

class SlackPluginTest < ActiveSupport::TestCase

  def setup
    @unique_id = Rails.root.join('app', 'plugins', 'slack_plugin.rb').to_s.to_sym

    @build = FactoryBot.create(:build)
    @build.project = FactoryBot.create(:project)
    @build.save

    @slack_plugin = SlackPlugin.new(@unique_id)
    @slack_plugin.add_plugin_settings_to_project(@build.project)
  end

  test 'create slack plugin and launch post request' do
    assert_not_empty(Rails.application.secrets.SLACK_WEBHOOK)
    slack_hook_url = "https://hooks.slack.com#{Rails.application.secrets.SLACK_WEBHOOK}"

    stub_request(:post, slack_hook_url).
        to_return(status: 200, body: "", headers: {})

    mock = MiniTest::Mock.new
    mock.expect(:send_build_commit_slack_update, {success: 'Message Sent'}, [@build])
    @slack_plugin.build_committed_hook(@build)
    assert_send([mock, :send_build_commit_slack_update, @build])

    build_failed_slack_response = @slack_plugin.build_failed_hook(@build)
    assert_equal(true, build_failed_slack_response.key?(:success))
  end

  test 'slack channel plugin setting has correct value' do
    project_settings_hash = @build.project.plugin_settings
    value = project_settings_hash[@slack_plugin.unique_id][:slack_channel][:value]
    assert_equal('test_channel', value)
  end

  test 'slack plugin loaded correctly' do
    plugin_manager = PluginManager.instance.for_project(@build.project)
    assert_not_nil(plugin_manager.plugins_hash[@unique_id])
  end
end