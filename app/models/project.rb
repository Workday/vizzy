class Project < ActiveRecord::Base
  has_many :builds, dependent: :delete_all
  serialize :plugin_settings, HashSerializer
  store_accessor :plugin_settings

  def github_repo_url
    if self.github_root_url.blank? || self.github_repo.blank?
      nil
    else
      self.github_root_url + '/' + self.github_repo
    end
  end

  def calculate_base_images
    images = []
    if self.builds.size == 0
      return images
    end
    self.tests.find_each do |test|
      image = test.current_base_image
      images.push(image) unless image.nil?
    end
    # Sort alphabetically
    images.sort_by! { |image| image.image_file_name.downcase }
    images
  end

  def remove_base_images_not_uploaded_in_last_branch_build
    branch_build = self.branch_builds.last
    return if branch_build.nil?
    base_images_to_remove = branch_build.get_base_images_not_uploaded
    return if base_images_to_remove.blank?
    test_ids = base_images_to_remove.map { |image| image.test_id }
    TestImage.joins(:test).where(test: test_ids).find_each { |image| image.remove_image_from_base_images }
  end

  def tests_ancestry_tree
    tests.arrange
  end

  def branch_builds
    builds.where(pull_request_number: '-1', temporary: false)
  end

  def pull_requests(pr_number = nil)
    if pr_number.nil?
      pr_builds = self.builds.where.not(pull_request_number: -1)
    else
      pr_builds = self.builds.where(pull_request_number: pr_number)
    end
    pr_builds.where(temporary: false)
  end

  def tests
    Test.where(project_id: self)
  end

  def uncommitted_builds
    builds.where(temporary: true)
  end
end
