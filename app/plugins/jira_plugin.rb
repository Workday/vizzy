class JiraPlugin < Plugin

  def initialize(unique_id)
    super(unique_id)
  end

  def add_plugin_settings_to_project(project)
    super(project, {
        jira_base_url: {
            value: get_jira_base_url(project),
            display_name: 'Base Jira Url',
            placeholder: "Add jira root url (e.g., 'https://jira.com')"
        },
        jira_project: {
            value: get_jira_project(project),
            display_name: 'Jira Project',
            placeholder: "Add jira project to file tickets (e.g., 'MOBILE')"
        },
        jira_component: {
            value: get_jira_component(project),
            display_name: 'Jira Component',
            placeholder: "Add jira component to file tickets (e.g., 'Visual Automation')"
        }
    })
  end

  private

  def get_jira_base_url(project)
    get_plugin_setting_value(project, :jira_base_url)
  end

  def get_jira_project(project)
    get_plugin_setting_value(project, :jira_project)
  end

  def get_jira_component(project)
    get_plugin_setting_value(project, :jira_component)
  end
end