FactoryBot.define do
  factory :jira do
    title 'Visual Automation Test Issue: LightColors_000000'
    project SystemTestConfig.jira_project
    component 'Visual Automation'
    description 'https://vizzy.com/diffs/21839'
    issue_type 'Bug'
    jira_link "#{SystemTestConfig.jira_base_url}/browse/MOBILEANDROID-13135"
    jira_key 'MOBILEANDROID-13135'
    diff_id 1
    priority 'Critical'
  end
end
