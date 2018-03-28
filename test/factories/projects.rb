def unique_id_for_plugin(plugin_name)
  Rails.root.join('app', 'plugins', plugin_name).to_s.to_sym
end

def bamboo_plugin_settings
  {
      enabled: true,
      base_bamboo_build_url: {
          value: SystemTestConfig.bamboo_base_url,
          display_name: 'Base Bamboo Url',
          placeholder: "Add base bamboo build url (e.g., 'https://bamboo.com')"
      }
  }
end

def slack_plugin_settings
  {
      enabled: true,
      slack_channel: {
          value: 'test_channel',
          display_name: 'Slack Channel',
          placeholder: "Add slack channel to send build results to (e.g., '#build-status')"
      }
  }
end

def jira_plugin_settings
  {
      enabled: true,
      jira_base_url: {
          value: SystemTestConfig.jira_base_url,
          display_name: 'Jira Base Url',
          placeholder: "Add jira root url (e.g., 'https://jira.com')"
      },
      jira_project: {
          value: SystemTestConfig.jira_project,
          display_name: 'Jira Project',
          placeholder: "Add jira project to file tickets (e.g., 'MOBILE')"
      },
      jira_component: {
          value: 'Visual Automation',
          display_name: 'Jira Component',
          placeholder: "Add jira component to file tickets (e.g., 'Visual Automation')"
      }
  }
end

def jenkins_plugin_settings
  {
      enabled: false
  }
end

FactoryBot.define do
  factory :project do
    name 'Testing'
    description 'A Testing Plan'
    github_root_url SystemTestConfig.github_root_url
    github_repo SystemTestConfig.github_repo
    github_status_context 'continuous-integration/vizzy'
    plugin_settings = {
        unique_id_for_plugin('bamboo_plugin.rb') => bamboo_plugin_settings,
        unique_id_for_plugin('slack_plugin.rb') => slack_plugin_settings,
        unique_id_for_plugin('jira_plugin.rb') => jira_plugin_settings,
        unique_id_for_plugin('jenkins_plugin.rb') => jenkins_plugin_settings
    }
    plugin_settings plugin_settings.deep_symbolize_keys!
  end
end
