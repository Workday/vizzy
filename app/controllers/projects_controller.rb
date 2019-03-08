class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :base_images, :remove_all_base_images, :clean_base_image_state, :cleanup_uncommitted_builds, :base_images_test_images]

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)
    save_plugin_settings(params[:plugin_settings], params[:enabled_plugins])

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    save_plugin_settings(params[:plugin_settings], params[:enabled_plugins])

    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def save_plugin_settings(settings, enabled_plugins)
    return if settings.blank?
    PluginManager.instance.for_project(@project).plugins_hash.each do |plugin|
      setting_key = plugin.first
      settings_hash = settings[setting_key] || {}
      settings_hash[:enabled] = if enabled_plugins.blank?
                                  false
                                else
                                  enabled_plugins[setting_key] == 'true'
                                end
      @project.plugin_settings[setting_key] = settings_hash
    end
  end

  # Deletes any uncommitted builds older than 4 hours (to prevent deleting builds that are in process)
  def cleanup_uncommitted_builds
    @project.builds.where(temporary: true).where('updated_at < ?', 4.hours.ago).order('id DESC').destroy_all
    redirect_back(fallback_location: project_path(@project))
  end

  # Removes all base images in the current project
  def remove_all_base_images
    @project.tests.each do |test|
      test.test_images.each { |image| image.remove_image_from_base_images }
    end
    redirect_back(fallback_location: root_path)
  end

  # Removes all base images that were not in the last branch build
  def clean_base_image_state
    @project.remove_base_images_not_uploaded_in_last_branch_build
    redirect_back(fallback_location: root_path)
  end

  def builds
    Build.find_by(project: @project)
  end

  def base_images
    render 'projects/base_images'
  end

  def base_images_test_images
    render 'projects/base_images_test_images'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    params.require(:project).permit(:name, :description, :github_root_url, :github_repo, :github_status_context)
  end

  protected

  def admin_only
    ['remove_all_base_images_project_path', 'clean_base_image_state_project_path', 'edit', 'destroy'].include?(action_name)
  end
end
