class JirasController < ApplicationController
  before_action :set_jira, only: [:show, :edit, :update, :destroy]

  # GET /jiras
  # GET /jiras.json
  def index
    @jiras = Jira.all
  end

  # GET /jiras/1
  # GET /jiras/1.json
  def show
  end

  # GET /jiras/new
  def new
    @jira = Jira.new(jira_params)
  end

  # GET /jiras/1/edit
  def edit
  end

  # POST /jiras
  # POST /jiras.json
  def create
    @jira = Jira.new(jira_params)

    respond_to do |format|
      if @jira.save
        response = create_jira
        if response.is_a?(Hash) && response.key?(:error)
          format.html { render :new }
          format.json { render json: {error: response[:error]}, status: :unprocessable_entity }
        else
          if @jira.jira_link
            format.html { redirect_to @jira.jira_link }
            format.json { render :show, status: :created, location: @jira }
          else
            format.html { redirect_to diff_path(@jira.diff_id), notice: response }
            format.json { render :show, status: :created, location: @jira }
          end
        end
      else
        format.html { render :new }
        format.json { render json: @jira.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /jiras/1
  # PATCH/PUT /jiras/1.json
  def update
    respond_to do |format|
      if @jira.update(jira_params)
        response = create_jira
        if response.is_a?(Hash) && response.key?(:error)
          format.html { render :edit }
          format.json { render json: {error: response[:error]}, status: :unprocessable_entity }
        else
          if @jira.jira_link
            format.html { redirect_to @jira.jira_link}
            format.json { render :show, status: :ok, location: @jira }
          else
            format.html { redirect_to diff_path(@jira.diff_id), notice: response }
            format.json { render :show, status: :ok, location: @jira }
          end
        end
      else
        format.html { render :edit }
        format.json { render json: @jira.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jiras/1
  # DELETE /jiras/1.json
  def destroy
    @jira.destroy
    respond_to do |format|
      format.html { redirect_to jiras_url, notice: 'Jira was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  def create_jira
    @jira.create_jira_request
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_jira
    @jira = Jira.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def jira_params
    params.require(:jira).permit(:title, :project, :component, :issue_type, :description, :jira_key, :jira_link, :priority, :diff_id, :jira_base_url)
  end
end
