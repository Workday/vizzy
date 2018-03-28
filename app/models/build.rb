require 'net/http'
require 'net/https'
class Build < ActiveRecord::Base
  serialize :image_md5s
  serialize :full_list_of_image_md5s
  serialize :associated_commit_shas
  has_and_belongs_to_many :base_images, class_name: 'TestImage', join_table: 'builds_base_images'
  has_and_belongs_to_many :successful_tests, class_name: 'TestImage', join_table: 'builds_successful_tests'
  has_many :test_images, dependent: :destroy
  has_many :diffs, dependent: :destroy
  belongs_to :project
  acts_as_commontable

  def new_tests
    test_images.where(build_id: id).where(image_created_this_build: true)
  end

  def missing_tests
    get_base_images_not_uploaded
  end

  def approved_diffs
    diffs.where(build_id: id).where(approved: true)
  end

  def unapproved_diffs
    diffs.where(build_id: id).where(approved: false)
  end

  def vizzy_build_url
    "#{self.project.vizzy_server_url}/builds/#{id}"
  end

  def get_base_images_not_uploaded
    return [] if self.temporary? || self.full_list_of_image_md5s.nil?
    self.base_images.where.not(test_key: self.full_list_of_image_md5s.keys)
  end

  def remove_md5_for_image(image)
    self.with_lock do # Since it's just a serialized hash, we have to take a lock to avoid overwriting the same data
      self.image_md5s.except!(image.test_key) # Remove from the upload list, to prevent duplicates
      self.save
    end
  end

  def fail_with_message(message)
    self.failure_message = message
    self.temporary = false
    self.save
    self.update_github_commit_status
  end

  # Returns a hash with the message and status (one of :pending, :success, :failure or :forced_failure)
  def current_state
    if !self.failure_message.nil?
      { message: self.failure_message, status: :forced_failure }
    elsif temporary
      { message: 'Running Visual Tests', status: :pending }
    else
      unapproved_count = self.unapproved_diffs.count
      approved_count = self.approved_diffs.count
      new_count = self.new_tests.count
      message_components = []
      message_components.push("#{new_count} new tests") if new_count > 0

      if unapproved_count > 0
        message_components.push("#{unapproved_count} unapproved diffs")
      end

      if approved_count > 0
        message_components.push("#{approved_count} approved diffs")
      end

      message = message_components.count > 0 ? message_components.join(', ') : '0 diffs'
      status = unapproved_count > 0 ? :failure : :success
      { message: message, status: status }
    end
  end

  def update_github_commit_status
    return if self.dev_build

    GithubService.run(self.project.github_root_url, self.project.github_repo) do |service|
      state = current_state
      message = state[:message]
      message += ' - Approval Needed' if state[:status] == :failure
      github_status = state[:status] == :forced_failure ? :failure : state[:status]
      service.send_status(self, github_status, message)
    end
  end

  # Queries github for metadata about the build, and stores it in the build object
  def fetch_github_information
    self.associated_commit_shas = []
    self.branch_name = nil
    self.username = nil

    return if self.dev_build

    GithubService.run(self.project.github_root_url, self.project.github_repo) do |service|
      if self.is_branch_build
        self.associated_commit_shas = service.github_commits(10, self.commit_sha)
        self.branch_name = nil
        self.username = nil
      else
        self.associated_commit_shas = []
        info = service.user_and_branch_for_pull_request(self.pull_request_number)
        self.username = info[:user]
        self.branch_name = info[:branch]
      end
    end
  end

  # Git shas are stored with an image when it is approved in a pull request. This function finds the list all shas associated with a build and returns all the preapproved images
  # This is the case when two developers made changes regarding the same test image, and both made the same build after being merged into develop
  #
  # @return preapproved_images -- Hash where the key is the test key, and the value is the array of preapproved images for that test
  def preapproved_images_for_branch
    preapproved_images = {}
    if self.is_branch_build
      self.associated_commit_shas.each do |sha|
        TestImage.where(image_pull_request_sha: sha, approved: false).select { |image| image.build.project.id == self.project.id }.each do |image|
          if preapproved_images.key?(image.test_key)
            if unique_preapproval_md5(preapproved_images[image.test_key], image)
              preapproved_images[image.test_key].push(image)
            else
              image.clear_preapproval_information(false)
              image.save
            end
          else
            preapproved_images[image.test_key] = [image]
          end
        end
      end
    end
    preapproved_images
  end

  def unique_preapproval_md5(preapproved_images, image)
    preapproved_images.each do |preapproved_image|
      return false if preapproved_image.md5 == image.md5
    end
    true
  end

  # Git shas and PR numbers are stored with an image when it is approved in a pull request. This function searches previous builds for matching PR number and returns the last image that got pre-approved
  #
  # @return previous_preapproved_images -- Hash where the key is the test key, and the value is the previously preapproved image for that test
  def previous_preapprovals_for_pull_request
    previous_preapproved_images = {}
    self.project.pull_requests(self.pull_request_number).each do |build|
      next if build == self

      build.test_images.where(image_pull_request_number: self.pull_request_number).where.not(image_pull_request_sha: nil).each do |image|
        previous_preapproved_images[image.test_key] = image
      end
    end
    previous_preapproved_images
  end

  # Pull Request Number is a string
  # @return true if pull request, false if not a pull request
  def is_branch_build
    self.pull_request_number == '-1'
  end

  def formatted_created_at_time
    self.created_at.strftime('%b %d, %Y %I:%M:%S %P ')
  end

  def update_dev_build_info
    return unless self.dev_build
    self.pull_request_number = nil
    self.branch_name = nil
    self.commit_sha = nil
    self.title = 'Dev Build'
  end

  def can_approve_images
    !self.temporary? && !self.dev_build?
  end
end
