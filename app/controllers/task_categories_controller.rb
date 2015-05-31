class TaskCategoriesController < ApplicationController

  skip_before_filter :verify_authenticity_token

  # GET /projects
  # GET /projects.json
  def index

    if params[:project_id]
      @task_categories = TaskCategory.joins(:project_task_category_assignments).where(project_task_category_assignments: { project_id: params[:project_id] }).uniq
      if @task_categories.count == 0
        @task_categories = TaskCategory.where(:is_default => true)
      end
    else
      @task_categories = TaskCategory.all
    end

    #if(params[:active])
    #else
    #  @projects = Project.all
    #end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @task_categories.to_json }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @task_category = TaskCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @task_category.to_json }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @task_category = TaskCategory.new(params[:task_category])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @task_category.to_json }
    end
  end

  # GET /projects/1/edit
  def edit
    @task_category = TaskCategory.find(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    @task_category = TaskCategory.with_deleted.find_or_initialize_by(name:  params[:task_category][:name])

    if @task_category.destroyed?
      @task_category.restore!
    else
      if @task_category.persisted?
        @task_category = nil
        
        respond_to do |format|
          format.html { render action: "new" }
          format.json { render json: {}, status: :unprocessable_entity }
        end
        return
      end
    end

    respond_to do |format|
      if @task_category.update_attributes(params[:task_category])
        format.html { redirect_to @task_category, notice: 'Task Category was successfully created.' }
        format.json { render json: @task_category.to_json, status: :created, location: @task_category }
      else
        format.html { render action: "new" }
        format.json { render json: @task_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @task_category = TaskCategory.find(params[:id])

    respond_to do |format|
      if @task_category.update_attributes(params[:task_category])
        format.html { redirect_to @task_category, notice: 'Task Category was successfully updated.' }
        format.json { render json: @task_category.to_json }
      else
        format.html { render action: "edit" }
        format.json { render json: @task_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @task_category = TaskCategory.find(params[:id])
    @task_category.destroy

    respond_to do |format|
      format.html { redirect_to task_categories_url }
      format.json { head :no_content }
    end
  end
end
