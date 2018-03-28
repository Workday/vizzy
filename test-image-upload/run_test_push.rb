#!/usr/bin/ruby

# To simplify common test cases

test_case = ARGV[0].to_i
is_develop = ARGV[1]
# Used for running builds via testing/CI
host_with_port = ARGV[2]
git_sha = ARGV[3]
pull_request_number = ARGV[4]

@is_system_test = !host_with_port.nil?
git_sha = "aa#{test_case}aaa" if git_sha.nil?
pull_request_number = '10' if pull_request_number.nil?

unless test_case > 0 && test_case <= 3
  puts "Unrecognized test case #{test_case}"
  exit(1)
end

visual_host = if host_with_port.nil?
                puts 'host_with_port is nil, falling back to http://localhost:3000'
                'http://localhost:3000'
              else
                puts "Host with port: #{host_with_port}"
                host_with_port
              end

auth_creds = "--user-email john.doe@gmail.com --user-token ht2Cey1i9xbxH5jm-gpx"
system("curl -O #{visual_host}/upload_images_to_server.rb")

create_arguments = "-p 1 -c #{git_sha} -f ./tmp-buildfile -t ANDROIDGITHUBBUILD-ANDRGITHUBPULLREQUEST-26740"
unless is_develop == '1'
  create_arguments += " --pull-request #{pull_request_number}"
end
puts "ruby ./upload_images_to_server.rb create #{visual_host} #{create_arguments} #{auth_creds}"
system("ruby ./upload_images_to_server.rb create #{visual_host} #{create_arguments} #{auth_creds}")

upload_args = "-f ./tmp-buildfile -d image_set#{test_case}"
upload_args.concat(' -e') if @is_system_test
puts "ruby ./upload_images_to_server.rb upload #{visual_host} #{upload_args} #{auth_creds}"
system("ruby ./upload_images_to_server.rb upload #{visual_host} #{upload_args} #{auth_creds}")

# Clean up downloaded files to avoid confusion
system('rm ./upload_images_to_server.rb')