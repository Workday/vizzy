namespace :wipeproject do
  desc 'Delete everything associated with the project id passed into the this rake task'
  task :destroy, [:project_id] => [:environment] do |t, args|

    project_id = args[:project_id].to_i
    @dry_run = %w(true 1).include? ENV['DRY_RUN']

    puts "Starting wipeprojects:destroy with project id #{project_id}"
    project = Project.find(project_id)
    builds_count = project.builds.size
    tests_count = project.tests.size

    if builds_count == 0 && tests_count == 0
      abort "Project with project id: #{project_id} has already been wiped clean. Exiting..."
    end

    if @dry_run
      puts "Builds That Would Have Been Deleted: #{builds_count}"
      puts "Test That Would Have Been Deleted: #{tests_count}"
    else
      project.builds.order("id DESC").destroy_all
      puts "Successfully Deleted #{builds_count} Builds From Project: #{project_id}"
      project.tests.order("id DESC").destroy_all
      puts "Successfully Deleted #{tests_count} Tests From Project: #{project_id}"
    end
  end
end
