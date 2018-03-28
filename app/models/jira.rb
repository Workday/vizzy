require 'net/http'
require 'net/https'
require 'net/http/post/multipart'
require 'json'

class Jira < ActiveRecord::Base
  belongs_to :diff
  validates_associated :diff

  # Create Jira with the given variables
  def create_jira_request
    begin
      should_create_issues = VizzyConfig.instance.get_config_value(['jira', 'create_issues'])
      return {success: 'Creating issues is turned off in vizzy.yaml'} unless should_create_issues

      set_priority
      create_request_service
      response_body = create_jira
      return response_body if response_body.key?(:error)
      self.jira_key = response_body['key']
      self.jira_link = "#{self.jira_base_url}/browse/#{self.jira_key}"
      self.save

      add_jira_link_to_test

      upload_attachments
    rescue StandardError => e
      Bugsnag.notify(e)
      puts "HTTP Request failed (#{e.message})"
    end
  end

  private
  def add_jira_link_to_test
    self.diff.old_image.test.jira = jira_link
    self.diff.old_image.test.save
  end

  def create_jira
    dict = {
        :fields => {
            :components => [
                {
                    :name => "#{self.component}"
                }
            ],
            :project => {
                :key => "#{self.project}"
            },
            :issuetype => {
                :name => "#{self.issue_type}"
            },
            :description => "#{self.description}",
            :summary => "#{self.title}",
            :assignee => {
                # -1 assigns to default user
                :name => "-1",
            },
            :priority => {
                :id => "#{self.priority}"
            },
        }
    }
    body = JSON.dump(dict)

    # Create Request
    req = Net::HTTP::Post.new(@path_prefix)
    # Add headers
    req.add_field 'Accept', 'application/json'
    # Set header and body
    req.add_field 'Content-Type', 'application/json'
    req.body = body

    @request_service.make_request(req)
  end

  def upload_attachments
    upload_image_to_jira(self.diff.old_image.image.path)
    upload_image_to_jira(self.diff.new_image.image.path)
    upload_image_to_jira(self.diff.differences.path)
  end

  def upload_image_to_jira(file_path)
    req = Net::HTTP::Post::Multipart.new("#{@path_prefix}/#{self.jira_key}/attachments", :file => UploadIO.new(file_path, 'image/png'))
    req.add_field("X-Atlassian-Token", "nocheck")
    @request_service.make_request(req)
  end

  def create_request_service
    user = Rails.application.secrets.JIRA_USERNAME
    pass = Rails.application.secrets.JIRA_PASSWORD
    @request_service = RequestService.new(self.jira_base_url, user, pass)
    @path_prefix = "/rest/api/2/issue"
  end

  # 3 is major, 2 is critical, 1 is blocker
  def set_priority
    if self.priority.eql? 'Blocker'
      self.priority = '1'
    elsif self.priority.eql? 'Critical'
      self.priority = '2'
    elsif self.priority.eql? 'Major'
      self.priority = '3'
    elsif self.priority.eql? 'Trivial'
      self.priority = '4'
    end
  end
end
