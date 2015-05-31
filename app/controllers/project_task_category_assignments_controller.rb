class ProjectTaskCategoryAssignmentsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  # GET /projects
  # GET /projects.json
  def index

    if params[:project_id]
      @project_task_category_assignments = ProjectTaskCategoryAssignment.where(project_id: params[:project_id]).load
    else
      @project_task_category_assignments = ProjectTaskCategoryAssignment.load
    end

    #if(params[:active])
    #else
    #  @projects = Project.all
    #end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @project_task_category_assignments.to_json(:include => [:project, :task_category]) }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project_task_category_assignment = ProjectTaskCategoryAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @project_task_category_assignment.to_json(:include => [:project, :task_category]) }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project_task_category_assignment = ProjectTaskCategoryAssignment.new(params[:project_task_category_assignment])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project_task_category_assignment.to_json(:include => [:project, :task_category]) }
    end
  end

  # GET /projects/1/edit
  def edit
    @project_task_category_assignment = ProjectTaskCategoryAssignment.find(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    @project_task_category_assignment = ProjectTaskCategoryAssignment.with_deleted.find_or_initialize_by(project_id: params[:project_task_category_assignment][:project_id], task_category_id:  params[:project_task_category_assignment][:task_category_id])

    if @project_task_category_assignment.destroyed?
      @project_task_category_assignment.restore!
    else
      if @project_task_category_assignment.persisted?
        @project_task_category_assignment = nil
        
        respond_to do |format|
          format.html { render action: "new" }
          format.json { render json: {}, status: :unprocessable_entity }
        end
        return
      end
    end

    respond_to do |format|
      if @project_task_category_assignment.update_attributes(params[:project_task_category_assignment])
        format.html { redirect_to @project_task_category_assignment, notice: 'Project Task Category Assignment was successfully created.' }
        format.json { render json: @project_task_category_assignment.to_json(:include => [:project, :task_category]), status: :created, location: @project_task_category_assignment }
      else
        format.html { render action: "new" }
        format.json { render json: @project_task_category_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project_task_category_assignment = ProjectTaskCategoryAssignment.find(params[:id])

    respond_to do |format|
      if @project_task_category_assignment.update_attributes(params[:project_task_category_assignment])
        format.html { redirect_to @project_task_category_assignment, notice: 'Project Task Category Assignment was successfully updated.' }
        format.json { render json: @project_task_category_assignment.to_json(:include => [:project, :task_category]) }
      else
        format.html { render action: "edit" }
        format.json { render json: @project_task_category_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project_task_category_assignment = ProjectTaskCategoryAssignment.find(params[:id])
    @project_task_category_assignment.destroy

    respond_to do |format|
      format.html { redirect_to project_task_category_assignments_url }
      format.json { head :no_content }
    end
  end
end
