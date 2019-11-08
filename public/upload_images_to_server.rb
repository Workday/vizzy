#!/usr/bin/ruby
# This script uploads images to the visual automation server. It calculates the image md5s, sends them with the build id request, the md5s are compared to the base image md5 on
# the server, generating a list of images that need to be uploaded that is returned with the build id. For usage of this script run with the --help flag.
require 'rubygems'
require 'json'
require 'digest/md5'
require 'net/http'
require 'net/https'
require 'net/http/post/multipart'
require 'benchmark'
require 'optparse'
require 'find'
require 'fileutils'
require 'pathname'

# --------------- Server ---------------- #

def create_server_client
  url = URI(@server_url)
  http = Net::HTTP.new(url.host, url.port)
  if @server_url.start_with?('https')
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.read_timeout = 300
  end
  http
end

def setup_shared_server_client
  @http = create_server_client
end

def setup_auth_creds(options)
  @vizzy_auth_email = options.user_email
  @vizzy_auth_token = options.user_token
end

def print_vizzy_link(build_id = nil)
  vizzy_build_link = @server_url
  vizzy_build_link += "/builds/#{build_id}" unless build_id.nil?
  puts "Vizzy Link: #{vizzy_build_link}"
end

def do_post(uri, body)
  perform_request(uri, body, false)
end

def do_get(uri)
  perform_request(uri, nil, true)
end

def add_vizzy_auth_headers(request)
  request.add_field 'X-User-Email', @vizzy_auth_email
  request.add_field 'X-User-Token', @vizzy_auth_token
end

def perform_request(uri, body, is_get)
  request = is_get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
  request.add_field 'Content-Type', 'application/json'
  request.add_field 'Accept', 'application/json'
  add_vizzy_auth_headers(request)
  request.body = JSON.dump(body) unless body.nil?
  fetch_request(request)
end

HTTP_RETRY_ERRORS = [
    Net::ReadTimeout,
    Net::HTTPBadGateway,
    Errno::ECONNRESET,
    Errno::EPIPE,
    Errno::ETIMEDOUT,
    Net::HTTPServiceUnavailable
]

# Fetch Request And Handle Errors
def fetch_request(request)
  max_retries = 3
  times_retried = 0

  begin
    response = @http.request(request)
    puts "Response HTTP Status Code: #{response.code}"
    puts "Response HTTP Response Body: #{response.body}"
    response
  rescue *HTTP_RETRY_ERRORS => e
    if times_retried < max_retries
      times_retried += 1
      puts "Error: #{e}, retry #{times_retried}/#{max_retries}"
      retry
    else
      puts "Error: #{e}, HTTP Request Failed: #{e.message}"
    end
  rescue StandardError => e
    puts "HTTP Request failed (#{e.message})"
  end
end

# --------------- Actions --------------- #

def fail_build(message, build_id = nil)
  puts "Build was not successful. Error: #{message}"
  unless build_id.nil?
    print_vizzy_link(build_id)
    body = { failure_message: message }
    do_post("/builds/#{build_id}/fail.json", body)
  end
  exit(1)
end

# Request (POST)
# Upload file to test_images controller with build id provided
def push_image_to_server(file_path, ancestry, build_id, thread_id, http)
  max_retries = 3
  times_retried = 0

  thread_puts = lambda do |msg|
    puts "||#{thread_id}|| #{msg}"
  end

  begin
    time = Benchmark.realtime do
      File.open(File.expand_path(file_path)) do |png|
        request = Net::HTTP::Post::Multipart.new '/test_images.json',
                                                 image: UploadIO.new(png, 'image/png'),
                                                 build_id: build_id,
                                                 test_image_ancestry: ancestry

        add_vizzy_auth_headers(request)
        response = http.request(request)

        thread_puts.call "Response HTTP Status Code: #{response.code}"
        thread_puts.call "Response HTTP Response Body: #{response.body}"

        if response.code == '502'
          # retry upload when we see a 502 server gateway error. Treat it as a read timeout.
          raise Net::ReadTimeout
        end
        response
      end
    end
    thread_puts.call "Time Spent: #{time}"
  rescue *HTTP_RETRY_ERRORS => e
    if times_retried < max_retries
      times_retried += 1
      thread_puts.call "Error: #{e}, retry #{times_retried}/#{max_retries}"
      retry
    else
      thread_puts.call "Error: #{e}, HTTP Request Failed: #{e.message}"
    end
  rescue StandardError => e
    thread_puts.call "HTTP Request failed (#{e.message})"
  end
end

# Request (POST)
# Gets build id and images to upload
def get_build_id(create_options)
  puts 'Requesting build id...'
  body = {
    title: create_options.title,
    project_id: create_options.project,
    commit_sha: create_options.commit,
    pull_request_number: create_options.pull_request_number,
    url: create_options.url,
    dev_build: create_options.dev_build
  }
  do_post('/builds.json', body)
end

# Request (POST)
# Sends a request to upload the generated md5s
def send_image_md5s(build_id, image_md5s)
  puts 'Sending md5s for the build'
  body = { image_md5s: image_md5s }
  response = do_post("/builds/#{build_id}/add_md5s.json", body)
  JSON.parse(response.body)
end

# Request (POST)
# Sends a request, finalizing the build transaction
def commit_build(build_id, total_upload_count)
  puts 'Committing the build'
  commit_response = do_post("/builds/#{build_id}/commit.json", nil)
  if commit_response.code != '200'
    uncommited_json = JSON.parse(commit_response.body)
    fail_build(uncommited_json['error'], build_id)
  else
    poll_for_commit(build_id, total_upload_count)
  end
end

def poll_for_commit(build_id, images_uploaded)
  puts 'Waiting for commit to finalize'
  sleep 2 # Sleep 2 before the first check so we can catch the 'simple' commits that have no diffs quickly

  # 360 tries * 10 seconds == 1 hour + scaling as needed
  max_tries = 360 + images_uploaded

  time_in_seconds = max_tries * 10
  time_in_minutes = time_in_seconds / 60
  puts "Polling Timeout Horizon: #{time_in_seconds} seconds == #{time_in_minutes} minutes"

  wait_time = 10
  total_wait_time = 0
  max_tries.times do
    response = do_get("/builds/#{build_id}/commit.json")
    if response.code != '200'
      fail_build('Failed to poll for commit status.', build_id)
      return nil
    else
      result = JSON.parse(response.body)
      return result if result['committed']
      puts "Build not committed, checking again in #{wait_time} seconds. Have already waited #{total_wait_time} seconds."
      total_wait_time += wait_time
      sleep wait_time
    end
  end
  fail_build("Build not committed after #{total_wait_time} seconds.", build_id)
end

def upload_images_to_build_with_id(id, images_to_upload, test_image_folder)
  return if images_to_upload.nil?
  total_upload_count = images_to_upload.size
  number_of_images_uploaded = 0
  file_list = traverse_directories(test_image_folder)
  file_list.select! { |file_info| images_to_upload.key?(file_info[:ancestry]) }

  threads = []
  semaphore = Mutex.new
  3.times do |thread_id|
    thread = Thread.new do
      # Create a separate http object for each thread so they don't clobber each others requests
      http = create_server_client
      loop do
        file_info = nil
        semaphore.synchronize do # Syncronize on the file list / image count
          next if file_list.empty?
          file_info = file_list.pop
          number_of_images_uploaded += 1
          puts "||#{thread_id}|| Uploading #{number_of_images_uploaded}/#{total_upload_count}: #{file_info[:file]}"
        end
        break if file_info.nil?
        push_image_to_server(file_info[:file], file_info[:ancestry], id, thread_id, http)
      end
    end
    threads.push(thread)
  end
  threads.each(&:join)
end

# Returns a hash containing each image name and the associated md5 for that image, as json
def compute_image_md5s_json(test_image_folder)
  image_md5s = {}
  traverse_directories(test_image_folder) do |ancestry, file|
    md5 = Digest::MD5.file(file).hexdigest
    image_md5s[ancestry] = md5
  end
  { count: image_md5s.size, json: image_md5s.to_json }
end

def traverse_directories(test_image_folder)
  results = []
  png_file_paths = get_png_file_paths(test_image_folder)

  Dir.chdir(test_image_folder) do
    test_image_folder_path = Dir.pwd
    png_file_paths.each do |file_path|

      file_path = file_path.gsub(test_image_folder, '')[1..-1]

      absolute_file_path = file_path
      unless Pathname.new(file_path).absolute?
        absolute_file_path = "#{test_image_folder_path}/#{file_path}"
      end

      filename = File.basename(absolute_file_path)

      if has_special_characters(filename)
        new_file_name = remove_special_characters(filename)
        new_absolute_file_path = get_new_file_path(absolute_file_path, new_file_name)
        absolute_file_path = rename_file(absolute_file_path, new_absolute_file_path)
      end

      ancestry_file_path = absolute_file_path.gsub(test_image_folder_path, '')[1..-1]
      ancestry = ancestry_file_path.rpartition('.').first

      if block_given?
        yield ancestry, absolute_file_path
      else
        results.push(ancestry: ancestry, file: absolute_file_path)
      end
    end
  end
  results unless block_given?
end

def get_new_file_path(absolute_file_path, new_file_name)
  path_array = absolute_file_path.split('/')
  path_array.pop
  path_array.push(new_file_name)
  path_array.join('/')
end

def rename_file(file_path, new_file_path)
  puts "Renaming file from: #{file_path} -> #{new_file_path}"
  File.rename(file_path, new_file_path)
  new_file_path
end

def get_png_file_paths(test_image_folder)
  Find.find(test_image_folder).select { |path| get_png_paths(path) }
end

def get_png_paths(path)
  path =~ /.*\.png/
end

# Remove special characters that do not play nicely with the rails filesystem
# U+0000 (NUL)
# / (slash)
# \ (backslash)
#: (colon)
# * (asterisk)
# ? (question mark)
# " (quote)
# < (less than)
# @ (At symbol)
# >(greater than)
# | (pipe)
@special_character_regexp = /[\x00\/\\:\*\?\"@<>\|]/

def remove_special_characters(filename)
  filename.gsub(@special_character_regexp, '_')
end

def has_special_characters(filename)
  filename =~ @special_character_regexp
end

# Traverses the folder structure and returns the number of images
def get_test_images_count(folder)
  Dir[File.join(folder, '**', '*')].count { |file| File.file?(file) }
end

# -------------- Script Start -------------- #

def validate_arguments(parser, options)
  unless block_given?
    puts 'Method requires block for required parameters'
    exit(1)
  end

  server_url = nil
  parser.order!(ARGV) do |arg|
    unless server_url.nil?
      puts 'Too many arguments!'
      puts parser
      exit(1)
    end
    server_url = arg
  end

  if server_url.nil?
    puts 'Missing server_url!'
    puts parser
    exit(1)
  end

  required_options = yield options

  required_options.each do |opt|
    next unless options[opt].nil?
    puts "Missing required option '--#{opt}'!"
    puts parser
    exit(1)
  end

  setup_auth_creds(options)
  @server_url = server_url
end

# Add auth and token to opts. Used for create, upload, and fail
def add_user_and_token_opts(options, opts)
  opts.on('--user-email EMAIL', 'Email used for token based authentication with Vizzy. Required') do |user_email|
    options.user_email = user_email
  end

  opts.on('--user-token TOKEN', 'Token used for token based authentication with Vizzy. NOTE: Only admins can create tokens. Required') do |user_token|
    options.user_token = user_token
  end
end

def create_command
  options = OpenStruct.new
  options.title = nil
  options.project = nil
  options.commit = nil
  options.file = nil
  options.pull_request_number = -1
  options.url = nil
  options.dev_build = false
  options.user_email = nil
  options.user_token = nil

  optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: upload_images_to_server.rb create <server-url> [options]'
    opts.on('-t', '--title TITLE', 'Title to supply for this build. Common usage is to match your CIs plan name + number') do |title|
      options.title = title
    end

    opts.on('-p', '--project ID', 'The project id to upload to. Required') do |id|
      options.project = id
    end

    opts.on('-c', '--commit HASH', 'Current git hash corresponding to this build. Required') do |hash|
      options.commit = hash
    end

    opts.on('-f', '--file BUILDFILE', 'File to store the created build information in. Used when running the "upload" command to commit the build. Required') do |file|
      options.file = file
    end

    opts.on('--pull-request PR_NUMBER', 'Pull request number to associate with this build. If not supplied build is treated as a "develop" build.') do |prNum|
      options.pull_request_number = prNum
    end

    opts.on('-u', '--url URL', 'url to the CI plan that created this build') do |url|
      options.url = url
    end

    opts.on('-d', '--developer-build', 'Used when a developer wants to simulate a pull request and check images against the server. Creates a \'dummy\' build where preapprovals will not work. Build deletes itself after 48 hours') do
      options.dev_build = true
    end

    add_user_and_token_opts(options, opts)

    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit(0)
    end
  end

  validate_arguments(optparse, options) do |parsed_options|
    required_options = [:user_email, :user_token, :project, :file]
    unless parsed_options[:dev_build]
      required_options = required_options + [:title, :commit]
    end
    required_options
  end

  # Remove existing build file
  FileUtils.rm_f(options.file)

  setup_shared_server_client

  build_id_response = get_build_id(options)
  if build_id_response.code != '201'
    error_message = 'Build ID Request Failed'
    begin
      parsed_data = JSON.parse(build_id_response)
      error_message = parsed_data['error'] unless parsed_data['error'].blank?
    rescue
      # ignored
    end
    fail_build(error_message)
  else
    json = build_id_response.body
    puts "Build Info: #{json}"
    File.write(options.file, json)

    id = JSON.parse(json)['id']
    puts "Link to in progress build: #{@server_url}/builds/#{id}"
  end
end

def print_build_summary(id, result)
  new_test_count = result['new_tests_count']
  unapproved_diffs_count = result['unapproved_diffs_count']
  missing_tests_count = result['missing_tests_count']
  successful_tests_count = result['successful_test_count']

  puts "-------------"
  puts "Build Summary"
  puts "-------------"
  puts "New Tests: #{new_test_count}"
  puts "Missing Tests: #{missing_tests_count}"
  puts "Successful Tests: #{successful_tests_count}"
  puts "Unapproved Diffs: #{unapproved_diffs_count}"
  print_vizzy_link(id)
  puts "-------------"
end

def upload_command
  options = OpenStruct.new
  options.file = nil
  options.directory = nil
  options.exit_0_on_diffs = false
  options.check_image_count = false
  options.user_email = nil
  options.user_token = nil

  optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: upload_images_to_server.rb upload <server-url> [options]'
    opts.on('-f', '--file BUILDFILE', 'File to store the created build information in. Used when running the "upload" command to commit the build.') do |file|
      options.file = file
    end
    opts.on('-d', '--directory IMAGEDIRECTORY', 'Directory to find images to upload.') do |directory|
      options.directory = directory
    end
    opts.on('-e', '--exit-0-on-diffs', 'Script will show as succeeded when diffs are present.') do
      options.exit_0_on_diffs = true
    end
    opts.on('-c', '--check-image-count', 'Script will fail if the number of images generated is less than the number of base images - 200.') do
      options.check_image_count = true
    end

    add_user_and_token_opts(options, opts)

    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit(0)
    end
  end

  validate_arguments(optparse, options) do
    [:file, :directory, :user_email, :user_token]
  end
  setup_shared_server_client

  build_dict = JSON.parse(File.read(options.file))

  id = build_dict['id']
  base_image_count = build_dict['base_image_count']
  puts "Uploading images to Vizzy build with ID: #{id}"
  puts "Base Image Count: #{base_image_count}"

  fail_build('Image Folder Empty', id) unless File.directory?(options.directory)

  number_of_images_generated = get_test_images_count(options.directory)
  puts "Number of images generated: #{number_of_images_generated}"
  image_md5s = compute_image_md5s_json(options.directory)
  puts "Number of md5s calculated: #{image_md5s[:count]}"

  puts "Listing Images Generated: #{image_md5s[:json]}"
  images_to_upload = send_image_md5s(id, image_md5s[:json])['image_md5s']
  total_upload_count = images_to_upload.size
  puts '=============================='
  puts "Number of Images to upload: #{total_upload_count}"
  puts "Images to upload: #{images_to_upload}"
  puts '=============================='

  upload_images_to_build_with_id(id, images_to_upload, options.directory)
  result = commit_build(id, total_upload_count)
  print_build_summary(id, result)

  if options.check_image_count && number_of_images_generated < (base_image_count * 0.8)
    error_message = "Did not generate enough images, number of images generated: #{number_of_images_generated} < (base image count: #{base_image_count} * 0.8)"
    fail_build(error_message, id)
  end

  unapproved_diffs_count = result['unapproved_diffs_count']

  if options.exit_0_on_diffs || unapproved_diffs_count == 0
    puts 'Exit(0)'
    exit(0)
  else
    puts 'In order to check in your code, please fix the tests/approve them, and rerun'
    puts 'Exit(1)'
    exit(1)
  end
end

def open_command
  options = OpenStruct.new
  options.file = nil
  optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: upload_images_to_server.rb open <server-url> [options]'
    opts.on('-f', '--file BUILDFILE', 'Build file that contains the build information of the build you want to open.') do |file|
      options.file = file
    end
    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit(0)
    end
  end

  validate_arguments(optparse, options) do
    [:file]
  end

  unless File.exists?(options.file)
    puts 'Build file does not exist. You must run \'create\' before running \'open\' for the file to be created properly.'
    exit(1)
  end

  build_dict = JSON.parse(File.read(options.file))
  id = build_dict['id']

  url = "#{@server_url}/builds/#{id}"

  `open #{url}`
end

def fail_command
  options = OpenStruct.new
  options.file = nil
  options.message = nil
  options.user_email = nil
  options.user_token = nil

  optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: upload_images_to_server.rb fail <server-url> [options]'
    opts.on('-f', '--file BUILDFILE', 'File to store the created build information in. Used when running the "upload" command to commit the build.') do |file|
      options.file = file
    end
    opts.on('-m', '--message FAILUREMESSAGE', 'Message to fail the build with. Server will use this message for slack and github status updates.') do |message|
      options.message = message
    end

    add_user_and_token_opts(options, opts)

    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
      exit(0)
    end
  end

  validate_arguments(optparse, options) do
    [:file, :message, :user_email, :user_token]
  end
  setup_shared_server_client

  build_dict = JSON.parse(File.read(options.file))

  id = build_dict['id']

  fail_build(options.message, id)
end

STDOUT.sync = true
STDERR.sync = true

top_level_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: upload_images_to_server.rb command [options]'
  opts.separator <<HELP
  Available commands are:
   create:     Creates a new build with the server. Saves the created build json into a provided file path
   upload:     Upload provided images. Reads in build information from a file (as generated by the 'create' command)
   open:       Opens a visual build in a browser referenced in the build information file as generated by the 'create' command.
   fail:       Fail the build referenced in the build information file as generated by the 'create' command )

See 'upload_images_to_server.rb COMMAND --help' for more information on a specific command.
HELP
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit(0)
  end
end

top_level_parser.order!(ARGV)
subcommand = ARGV.shift
if subcommand.nil?
  puts 'Missing command!'
  puts top_level_parser
  exit(1)
end

case subcommand
  when 'create'
    create_command
  when 'upload'
    upload_command
  when 'open'
    open_command
  when 'fail'
    fail_command
else
  puts "Unknown subcommand #{subcommand}!"
  exit(1)
end
