require 'digest/md5'
class BuildsController < ApplicationController
  before_action :set_build, only: [:show, :edit, :update, :destroy, :unapproved_diffs, :approved_diffs, :approve_all_images, :new_tests, :missing_tests, :add_md5s, :commit, :successful_tests, :fail]
  skip_before_action :verify_authenticity_token, only: [:create, :add_md5s, :fail, :commit], if: :json_request?

  # GET /builds
  # GET /builds.json
  def index
    @builds = Build.all
  end

  # GET /builds/1
  # GET /builds/1.json
  def show
  end

  # GET /builds/new
  def new
    @build = Build.new
  end

  # GET /builds/1/edit
  def edit
  end

  # POST /builds
  # POST /builds.json
  def create
    begin
      @build = Build.new(build_params)
      @build.temporary = true
      if @build.project.nil?
        raise "Project #{build_params[:project_id]} does not exist"
      end
      update_vizzy_url_if_necessary(request.base_url)
      @build.base_images = @build.project.calculate_base_images
      @build.fetch_github_information
      @build.update_dev_build_info
    rescue StandardError => e
      Bugsnag.notify(e)
      project = Project.find(build_params[:project_id])
      hash = build_params[:commit_sha]
      url_to_link = build_params[:url].blank? ? request.base_url : build_params[:url]
      failure_message = e.message
      if !@build.dev_build && !project.nil?
        GithubService.run(project.github_root_url, project.github_repo) do |service|
          service.send_project_status(project, url_to_link, hash, :failure, failure_message)
        end
      end
      respond_to do |format|
        format.html { redirect_to projects_path, notice: failure_message }
        format.json { render json: { error: failure_message }, status: :internal_server_error }
      end
      return
    end

    respond_to do |format|
      if @build.save
        @build.update_github_commit_status
        results = PluginManager.instance.for_project(@build.project).run_build_created_hook(@build)
        if results[:errors].blank?
          format.html {redirect_to @build, notice: 'Build was successfully created.'}
          format.json {render :show, status: :created, location: @build}
        else
          format.html {render :new}
          format.json {render json: {error: results[:errors]}, status: :internal_server_error}
        end
      else
        format.html { render :new }
        format.json { render json: @build.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /fail
  # POST /fail.json
  def fail
    respond_to do |format|
      if !@build.temporary?
        format.html {redirect_to build_path(@build), alert: 'Cannot fail a build that has already been committed'}
        format.json {render json: {error: 'Cannot fail a build that has already been committed'}, status: :bad_request}
      else
        @build.fail_with_message(build_params[:failure_message])
        results = PluginManager.instance.for_project(@build.project).run_build_failed_hook(@build)
        error_messages = results[:errors]
        if error_messages.blank?
          format.html {redirect_to @build, notice: 'Build failed.'}
          format.json {render :show, status: :ok, location: @build}
        else
          format.html {render :new}
          format.json {render json: {error: error_messages}, status: :internal_server_error}
        end
      end
    end
  end

  def add_md5s
    respond_to do |format|
      if !@build.temporary?
        format.html { redirect_to build_path(@build), alert: 'Cannot add md5s to a committed build' }
        format.json { render json: { error: 'Cannot add md5s to a committed build' }, status: :bad_request }
      elsif !@build.image_md5s.blank?
        format.html { redirect_to build_path(@build), alert: 'Build already has md5s associated with it!' }
        format.json { render json: { error: 'Build already has md5s associated with it!' }, status: :bad_request }
      else
        @build.image_md5s = JSON.parse(build_params[:image_md5s]) || {}
        @build.full_list_of_image_md5s = @build.image_md5s

        # Update number of images in build to keep track
        @build.num_of_images_in_build = @build.full_list_of_image_md5s.size
        remove_matching_md5s_from_hash

        @build.image_md5s.each do |key, md5|
          ensure_test_exists(key)
        end

        if @build.save
          format.html { redirect_to @build, notice: 'Md5s successfully added' }
          format.json { render :show, status: :ok, location: @build }
        else
          format.html { render :new }
          format.json { render json: @build.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def commit
    if request.get?
      respond_to do |format|
        if @build.temporary
          format.json { render json: { committed: false } }
        else
          format.json {render json: {committed: true, successful_test_count: @build.successful_tests.size, missing_tests_count: @build.missing_tests.size, unapproved_diffs_count: @build.unapproved_diffs.size, new_tests_count: @build.new_tests.size}}
        end
      end
    elsif request.post?
      respond_to do |format|
        unless @build.temporary?
          format.html { redirect_to build_path(@build), alert: 'Build already committed!' }
          format.json { render json: { error: 'Build already committed!' }, status: :bad_request }
          next
        end

        unless @build.image_md5s.empty?
          format.html { redirect_to build_path(@build), alert: "Not all images uploaded before commit! Missing #{@build.image_md5s.keys}" }
          format.json { render json: { error: "Not all images uploaded before commit! Missing #{@build.image_md5s.keys}" }, status: :bad_request }
          next
        end

        BuildBackgroundCommitJob.perform_later(@build)
        format.html { redirect_to @build, notice: 'Build commit in progress' }
        format.json { render :show, status: :ok, location: @build }
      end
    end
  end

  # Looks through image_md5s and base images and deletes the entry from the hash if there is a match. This leaves a list of images that need to be uploaded stored in
  # image_md5s
  def remove_matching_md5s_from_hash
    preapproved_images = @build.preapproved_images_for_branch
    @build.base_images.find_each(batch_size: 500) do |image|
      @build.image_md5s.delete_if do |key, value|
        # Delete the image if the md5, filename match and if there aren't preapprovals pending. If there are, the image needs to be
        # uploaded because it could create diffs -- see handle_pull_request_preapproval_case in test_images_controller
        preapprovals = preapproved_images[image.test_key]
        if found_matching_md5_and_filename(key, value, image) && preapprovals.blank?
          @build.successful_tests.push(image)
          next true
        end
        next false
      end
    end
  end

  # key and value of test image and base image is passed, returns true if they are a match
  def found_matching_md5_and_filename(key, value, image)
    !key.nil? && !value.nil? && !image.nil? && !image.md5.nil? && value.chomp == image.md5.chomp && key.chomp == image.test_key.chomp
  end

  # PATCH/PUT /builds/1
  # PATCH/PUT /builds/1.json
  def update
    respond_to do |format|
      if @build.update(build_params)
        format.html { redirect_to @build, notice: 'Build was successfully updated.' }
        format.json { render :show, status: :ok, location: @build }
      else
        format.html { render :edit }
        format.json { render json: @build.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /builds/1
  # DELETE /builds/1.json
  def destroy
    @build.destroy
    respond_to do |format|
      format.html { redirect_to builds_url, notice: 'Build was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def approve_all_images
    if @build.temporary?
      redirect_to build_path(@build), alert: 'Cannot approve images until build has been committed'
    else
      @unapproved_diffs.each do |diff|
        diff.approve(current_user)
        diff.save
      end

      @build.update_github_commit_status

      redirect_to build_path(@build)
    end
  end

  def unapproved_diffs
    @diffs = @unapproved_diffs
    render 'diffs/index'
  end

  def approved_diffs
    @diffs = @approved_diffs
    render 'diffs/index'
  end

  def new_tests
    @test_images = @new_tests
    render 'test_images/index'
  end

  def missing_tests
    @test_images = @missing_tests
    render 'test_images/missing_tests'
  end

  def successful_tests
    @test_images = @successful_tests
    render 'test_images/successful_tests'
  end

  private
  def update_vizzy_url_if_necessary(request_url)
    if @build.project.vizzy_server_url != request_url
      @build.project.vizzy_server_url = request_url
      @build.project.save
    end
  end

  def ensure_test_exists(ancestry_key)
    Test.create_or_find(@build.project_id, ancestry_key)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_build
    @build = Build.find(params[:id])
    @unapproved_diffs = @build.unapproved_diffs
    @approved_diffs = @build.approved_diffs
    @new_tests = @build.new_tests
    @missing_tests = @build.missing_tests
    @successful_tests = @build.successful_tests
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def build_params
    params.require(:build).permit(:url, :temporary, :title, :project_id, :pull_request_number, :commit_sha, :dev_build, :image_md5s, :failure_message)
  end
end
