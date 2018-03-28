def run_build(params, args)
  Dir.chdir Rails.root.join('test-image-upload')
  build_command = "ruby run_test_push.rb #{params} #{args[:host_with_port]}"
  git_sha = args[:git_sha]
  build_command.concat(" #{git_sha}") unless git_sha.nil?
  pull_request_number = args[:pull_request_number]
  build_command.concat(" #{pull_request_number}") unless pull_request_number.nil?
  system(build_command)
end

namespace :run_test_build do
############## BUILD DEVELOPS ##############

  desc 'run a ruby script'
  task :develop_1, [:host_with_port, :git_sha] => [:environment] do |_, args|
    puts 'running develop 1...'
    run_build('1 1', args)
  end

  task :develop_2, [:host_with_port, :git_sha] => [:environment] do |_, args|
    puts 'running develop 2...'
    run_build('2 1', args)
  end

  task :develop_3, [:host_with_port, :git_sha] => [:environment] do |_, args|
    puts 'running develop 3...'
    run_build('3 1', args)
  end

  ############## PULL REQUESTS ##############

  task :pull_request_1, [:host_with_port, :git_sha, :pull_request_number] => [:environment] do |_, args|
    puts 'running pull request 1...'
    run_build('1 2', args)
  end

  task :pull_request_2, [:host_with_port, :git_sha, :pull_request_number] => [:environment] do |_, args|
    puts 'running pull request 2...'
    run_build('2 2', args)
  end

  task :pull_request_3, [:host_with_port, :git_sha, :pull_request_number] => [:environment] do |_, args|
    puts 'running pull request 3...'
    run_build('3 2', args)
  end
end