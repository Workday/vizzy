class BambooPlugin < Plugin

  def initialize(unique_id)
    super(unique_id)
    @username = Rails.application.secrets.BAMBOO_USERNAME
    @password = Rails.application.secrets.BAMBOO_PASSWORD
  end

  # Add bamboo base url project plugin settings
  # Params:
  # - project: project to add settings to
  def add_plugin_settings_to_project(project)
    super(project, {
        base_bamboo_build_url: {
            value: get_base_bamboo_url(project),
            display_name: 'Base Bamboo Url',
            placeholder: "Add base bamboo build url (e.g., 'https://bamboo.com')"
        }
    })
  end

  # Comment on bamboo build when Vizzy build is created
  # Params:
  # - build: build object containing relevant info
  def build_created_hook(build)
    return {dev_build: 'Dev Build, Not Running Bamboo Plugin Hook'} if build.dev_build
    comment_on_build(build)
  end

  private
  def find_or_create_request_service
    @service = @service ||= RequestService.new(@base_bamboo_build_url, @username, @password)
  end

  # Add comment to bamboo build with link to the visual build
  # Params:
  # - build: build object containing all relevant info
  def comment_on_build(build)
    should_comment_on_build = VizzyConfig.instance.get_config_value(['bamboo', 'comment_on_build'])
    return {success: 'Commenting on builds is turned off in vizzy.yaml'} unless should_comment_on_build

    return {error: "Bamboo Request Info Blank"} if @username.blank? || @password.blank? || build.title.blank? || build.vizzy_build_url.blank?
    puts "Adding comment to bamboo with key #{build.title} with build url: #{build.vizzy_build_url }"


    @base_bamboo_build_url = get_base_bamboo_url(build.project)
    return {error: "Bamboo Build Url Blank"} if @base_bamboo_build_url.blank?

    find_or_create_request_service

    dict = {
        content: build.vizzy_build_url
    }

    # Create Request
    request = Net::HTTP::Post.new("/rest/api/latest/result/#{build.title}/comment")
    request.add_field 'Content-Type', 'application/json'
    request.add_field 'Accept', 'application/json'
    request.body = JSON.dump(dict)
    response = @service.make_request(request)
    # Don't fail the vizzy build if the bamboo response comes back with 'Not Found', just print the error
    if response[:error] == "Not Found"
      puts "Error: Bamboo build not found, did not successfully comment on the build."
      return {success: "Ok"}
    end
    response
  end

  # Add bamboo url from project plugin settings
  # Params:
  # - project: project to look for plugin settings
  def get_base_bamboo_url(project)
    get_plugin_setting_value(project, :base_bamboo_build_url)
  end
end