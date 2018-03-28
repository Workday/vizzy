class SlackPlugin < Plugin

  def initialize(unique_id)
    super(unique_id)
  end

  # Add slack channel to project plugin settings
  # Params:
  # - project: project to add settings to
  def add_plugin_settings_to_project(project)
    super(project, {
        slack_channel: {
            value: get_slack_channel(project),
            display_name: 'Slack Channel',
            placeholder: "Add slack channel to send build results to (e.g., '#build-status')"
        }
    })
  end

  # send slack message when a build commits
  # Params:
  # - build: build object containing relevant info
  def build_committed_hook(build)
    return {dev_build: 'Dev Build, Not Running Bamboo Plugin Hook'} if build.dev_build
    send_build_commit_slack_update(build)
  end

  # send slack message when a build fails
  # Params:
  # - build: build object containing relevant info
  def build_failed_hook(build)
    return {dev_build: 'Dev Build, Not Running Bamboo Plugin Hook'} if build.dev_build
    send_build_commit_slack_update(build)
  end

  private
  def find_or_create_request_service
    @service = @service ||= RequestService.new('https://hooks.slack.com')
  end

  # Get slack channel from project plugin settings
  # Params:
  # - project: project to look for plugin settings
  def get_slack_channel(project)
    get_plugin_setting_value(project, :slack_channel)
  end

  # Send build commit slack message
  # Params:
  # - build: build object containing relevant info
  def send_build_commit_slack_update(build)
    should_create_issues = VizzyConfig.instance.get_config_value(['slack', 'send_messages'])
    return {success: 'Sending messages is turned off in vizzy.yaml'} unless should_create_issues

    state = build.current_state
    links = get_links(build)
    channel = get_channel(build)
    message = get_message(build, state)

    send_message(channel, build.project.name, build.branch_name, message, links, state[:status] == :failure || state[:status] == :forced_failure)
  end

  # Get links for build system, visual automation, and github
  # Params:
  # - build: build object containing relevant info
  def get_links(build)
    links = []
    unless build.url.blank?
      links.append({url: build.url, text: 'Build'})
    end
    links.append({url: build.vizzy_build_url, text: 'Visual Automation'})
    unless build.is_branch_build
      links.append({url: "#{build.project.github_repo_url}/pull/#{build.pull_request_number}", text: 'Github'})
    end
    links
  end

  # Get slack channel. if build is a pull request, the slack channel will be the user who created the build. Otherwise channel will be retrieved from the plugin settings
  # Params:
  # - build: build object containing username and project
  def get_channel(build)
    channel = ''
    if build.is_branch_build
      channel = get_slack_channel(build.project)
    elsif !build.username.blank?
      channel = "@#{build.username}"
    end
    channel
  end

  # Get a brief summary of build state
  # Params:
  # - build: build object containing relevant info
  # - state: hash of the current state of the build, contains :message and :status
  def get_message(build, state)
    message = ""
    if state[:status] == :forced_failure
      if build.is_branch_build
        message += "The visual build has failed!"
      else
        message += "Your pull request visual build has failed!"
      end
      message += " #{state[:message]}"
    elsif build.is_branch_build
      message += "A visual build just successfully finished with #{state[:message]}"
      if state[:status] == :success
        message += '! :smile2:'
      else
        message += '. Please fix or approve them.'
      end
    else
      message += "Your pull request visual build successfully finished with #{state[:message]}"
      if state[:status] == :success
        message += '! Great job, if the other parts of your build have completed successfully, you may check in your code!'
      else
        message += '. Please fix or approve them.'
      end
    end
    message
  end

  # Sends a slack message
  # Params:
  # - channel: channel to send the slack message to
  # - project_name: title of the slack message
  # - branch_name: source control branch name if present, can be nil
  # - message: brief summary of build state
  # - links: an array of hashes representing a link, with keys 'text', and 'url'
  # - failure: whether or not the build failed, determines message color
  def send_message(channel, project_name, branch_name, message, links, failure=false)
    if channel.blank?
      return {error: "Slack Channel Blank"}
    end

    color = failure ? '#B0171F' : '#7CD197'
    pretext = message
    fallback = message + 'Links: ' + links.collect {|link| link[:text] + ': ' + link[:url]}.join(', ')
    text = links.collect {|link| "<#{link[:url]}|#{link[:text]}>" }.join("\n")
    title = project_name
    unless branch_name.nil?
      title += " - #{branch_name}"
    end

    puts "Sending slack message to user: #{channel} with message: #{pretext}"
    dict = {
        channel: "#{channel}",
        username: "Vizzy",
        icon_emoji: ":vizzy:",
        attachments: [
            {
                fallback: fallback,
                pretext: pretext,
                title: title,
                text: text,
                color: color
            }
        ]
    }

    find_or_create_request_service
    request = Net::HTTP::Post.new(Rails.application.secrets.SLACK_WEBHOOK)
    request.add_field 'Content-Type', 'application/json'
    request.add_field 'Accept', 'application/json'
    request.body = JSON.dump(dict)
    @service.make_request(request)
  end
end