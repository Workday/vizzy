class SystemTestConfig
  include Singleton

  # Github
  def self.github_root_url
    Rails.application.secrets.GITHUB_ROOT_URL || 'https://github.com'
  end

  def self.github_repo
    Rails.application.secrets.GITHUB_REPO || 'mobile/android'
  end

  # Jira
  def self.jira_base_url
    Rails.application.secrets.JIRA_BASE_URL || 'https://jira.com'
  end

  def self.jira_project
    Rails.application.secrets.JIRA_PROJECT || 'MOBILE'
  end

  # Bamboo
  def self.bamboo_base_url
    Rails.application.secrets.BAMBOO_BASE_URL || 'https://bamboo.com'
  end
end