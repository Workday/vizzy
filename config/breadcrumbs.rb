crumb :projects do
  link 'Projects', projects_path
end

crumb :project do |project|
  link project.name, project_path(project)
  parent :projects
end

crumb :builds do
  link 'Builds', builds_path
end

crumb :build do |build|
  link build.title, build_path(build)
  parent build.project
end

crumb :diffs do
  link 'Diffs', diffs_path
end

crumb :diff do |diff|
  link "Diff: #{diff.new_image.test_key}", diff_path(diff)
  parent diff.build
end

crumb :jiras do
  link 'Jiras', jiras_path
end

crumb :jira do |jira|
  link 'Create Jira', jira_path(jira)
  parent jira.diff
end

crumb :test_images do
  link 'Test Images', test_images_path
end

crumb :test_image do |test_image|
  link test_image.image_file_name, test_image_path(test_image)
  parent test_image.build
end

crumb :test do |test|
  link test.name, test_path(test)
  if test.parent.nil?
    parent Project.find(test.project_id)
  else
    parent test.parent
  end
end

crumb :base_images do |project|
  link 'Base Images', project_path(project)
  parent project
end

crumb :base_images_test_images do |project|
  link 'Base Images Test Images', project_path(project)
  parent project
end

crumb :users do
  link 'Users', users_path
end

crumb :user do |user|
  link user.display_name, user_path(user)
  parent :users
end

crumb :missing_tests do |build|
  link 'Missing Tests', builds_path(build)
  parent build
end

crumb :successful_tests do |build|
  link 'Successful Tests', builds_path(build)
  parent build
end