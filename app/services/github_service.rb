class GithubService
  def initialize(server_url, repo)
    @token = Rails.application.secrets.GITHUB_AUTH_TOKEN
    @path_prefix = "/api/v3/repos/" + repo
    @request_service = RequestService.new(server_url, @token, "x-oauth-basic")
  end

  # Static method that takes a block with the service, also runs some validations
  def self.run(server_url, repo)
    if server_url.blank? or repo.blank?
      return false
    end

    service = GithubService.new(server_url, repo)
    yield(service)
    true
  end

  # Sends a status without a build
  def send_project_status(project, url, hash, status, description)
    path = @path_prefix + "/statuses/#{hash}"
    context = project.github_status_context
    dict = {
        target_url: url,
        state: status,
        description: description,
        context: context
    }
    make_request(path, false, dict)
  end

  def send_status(build, status, description)
    send_project_status(build.project, build.vizzy_build_url, build.commit_sha, status, description)
  end

  def github_commits(number_of_days_ago, from_commit)
    current_page = 0
    all_commits = Array.new
    begin
      current_page += 1
      json_response = pagination_github_commits(number_of_days_ago, from_commit, current_page)
      if json_response.is_a?(Hash) && json_response.key?(:error)
        puts "Failed request, returning empty array for git commits"
        return []
      end
      shas_array = json_response.collect { |commit| commit['sha'] }
      all_commits.concat(shas_array)
    end while json_response.size == 100

    all_commits
  end

  # Used for testing preapprovals
  def most_recent_github_commits
    path = @path_prefix + "/commits"
    json_response = make_request(path, true, nil)
    if json_response.is_a?(Hash) && json_response.key?(:error)
      puts "Failed request, returning empty array for git commits"
      return []
    end
    json_response.collect { |commit| commit['sha'] }
  end

  def user_and_branch_for_pull_request(pr_num)
    pr = make_request(@path_prefix + "/pulls/#{pr_num}", true, nil)
    # Validate we didn't get an error
    if pr.key?(:error)
      raise("Failed to get user and branch information for pull request ##{pr_num}")
    end

    branch = pr['head']['ref']
    # Use ldap info instead of 'login' so we get the official AD username without needing a whitelist for names with hyphens
    # Looking at you 'erh-li.shen'
    ldap_info = pr['user']['ldap_dn']
    user = /CN=(.*?),/.match(ldap_info).captures[0]
    {branch: branch, user: user}
  end

  private
  def pagination_github_commits(number_of_days_ago, from_commit, page_number)
    days_ago = number_of_days_ago.days.ago.to_time.iso8601

    path = @path_prefix + "/commits?since=#{days_ago}&sha=#{from_commit}&per_page=100&page=#{page_number}"
    make_request(path, true, nil)
  end

  def make_request(path, is_get, json_dict)
    request = is_get ? Net::HTTP::Get.new(path) : Net::HTTP::Post.new(path)
    request.add_field 'Content-Type', 'application/json'
    request.add_field 'Accept', 'application/json'
    unless json_dict.nil?
      body = JSON.dump(json_dict)
      request.body = body
    end

    @request_service.make_request(request)
  end
end
