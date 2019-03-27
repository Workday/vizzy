class DiffsController < ApplicationController
  before_action :set_diff, only: [:show, :edit, :update, :destroy, :approve, :unapprove, :next, :multiple_diff_approval, :create_jira]

  # GET /diffs
  # GET /diffs.json
  def index
    @diffs = Diff.all
  end

  # GET /diffs/1
  # GET /diffs/1.json
  def show
    commontator_thread_show(@diff.new_image)
  end

  # GET /diffs/new
  def new
    @diff = Diff.new
  end

  # GET /diffs/1/edit
  def edit
  end

  # POST /diffs
  # POST /diffs.json
  def create
    @diff = Diff.new(diff_params)

    respond_to do |format|
      if @diff.save
        format.html { redirect_to @diff, notice: 'Diff was successfully created.' }
        format.json { render :show, status: :created, location: @diff }
      else
        format.html { render :new }
        format.json { render json: @diff.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /diffs/1
  # PATCH/PUT /diffs/1.json
  def update
    respond_to do |format|
      if @diff.update(diff_params)
        format.html { redirect_to @diff, notice: 'Diff was successfully updated.' }
        format.json { render :show, status: :ok, location: @diff }
      else
        format.html { render :edit }
        format.json { render json: @diff.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diffs/1
  # DELETE /diffs/1.json
  def destroy
    @diff.destroy
    respond_to do |format|
      format.html { redirect_to diffs_url, notice: 'Diff was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def create_jira
    plugin_hash = params[:plugin_hash]
    jira_base_url = plugin_hash[:jira_base_url][:value]
    jira_project = plugin_hash[:jira_project][:value]
    jira_component = plugin_hash[:jira_component][:value]

    jira_args = {
      description: "#{@diff.build.project.vizzy_server_url}/diffs/#{@diff.id}",
      project: jira_project,
      component: jira_component,
      title: "Vizzy Issue: #{@diff.old_image.test.ancestry_key}",
      diff_id: @diff.id,
      jira_base_url: jira_base_url
    }
    redirect_to new_jira_path(jira: jira_args)
  end

  def approve
    unless @diff.build.can_approve_images
      redirect_to diff_path(@diff), alert: 'Cannot modify diffs until build has been committed'
      return
    end

    @diff.approve(current_user)
    puts 'Redirecting to next diff'
    go_to_next_diff_or_build_page
  end

  def unapprove
    unless @diff.build.can_approve_images
      redirect_to diff_path(@diff), alert: 'Cannot modify diffs until build has been committed'
      return
    end

    @diff.unapprove
    @diff.build.update_github_commit_status
    puts 'Redirecting to build page'
    redirect_to build_path(@diff.build)
  end

  # Build Develop Build Only - Special case method for when multiple developers make changes on the same image, view with multiple diffs shows and they are allowed to
  # approve either one of the old images
  def multiple_diff_approval
    if @diff.build.temporary?
      redirect_to diff_path(@diff), alert: 'Cannot modify diffs until build has been committed'
      return
    end

    @diff.approve_old_image(current_user)
    puts 'Redirecting to next diff'
    go_to_next_diff_or_build_page
  end

  # Redirect to next diff or to the build if no more diffs
  def go_to_next_diff_or_build_page
    @diff.build.update_github_commit_status
    if @diff.build.unapproved_diffs.empty?
      puts 'Redirecting to build overview'
      redirect_to build_path(@diff.build)
      return
    end

    last_diff = @diff.build.unapproved_diffs.last
    next_diff = nil
    next_diff_id = @diff.id

    while next_diff.nil? && !@diff.build.unapproved_diffs.empty?
      next_diff_id += 1

      if next_diff_id > last_diff.id
        # out of bounds, go back to the beginning
        next_diff = @diff.build.unapproved_diffs.first
        break
      end

      begin
        next_diff = @diff.build.diffs.find_by_id(next_diff_id)
      rescue RecordNotFound => e
        Bugsnag.notify(e)
        puts e
        next
      end

      if !next_diff.nil? && (next_diff.approved || next_diff.old_image.test_key == @diff.old_image.test_key || !(next_diff.build.id == @diff.build.id))
        next_diff = nil
      end
    end

    redirect_to diff_path(next_diff)
  end

  # Navigate to the next diff that needs approval
  def next
    puts 'Clicked next'
    go_to_next_diff_or_build_page
    # Navigate to the next diff that needs approval
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_diff
    @diff = Diff.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def diff_params
    params.require(:diff).permit(:old_image_id, :new_image_id)
  end
end
