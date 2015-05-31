class ProjectParticipantsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  # GET /projects
  # GET /projects.json
  def index

    #if(params[:active])
      @project_participants = ProjectParticipant.all.load
    #else
    #  @projects = Project.all
    #end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @project_participants.to_json(:include => [:project, :user, :contact]) }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project_participant = ProjectParticipant.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @project_participant.to_json(:include => [:project, :user, :contact]) }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project_participant = ProjectParticipant.new(params[:project_participant])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project_participant.to_json(:include => [:project, :user, :contact]) }
    end
  end

  # GET /projects/1/edit
  def edit
    @project_participant = ProjectParticipant.find(params[:id])
  end

  # POST /projects
  # POST /projects.json
  def create
    @project_participant = ProjectParticipant.with_deleted.find_or_initialize_by(project_id: params[:project_participant][:project_id], user_id:  params[:project_participant][:user_id])

    if @project_participant.destroyed?
      @project_participant.restore!
    else
      if @project_participant.persisted?
        @project_participant = nil
        
        respond_to do |format|
          format.html { render action: "new" }
          format.json { render json: {}, status: :unprocessable_entity }
        end
        return
      end
    end

    respond_to do |format|
      if @project_participant.update_attributes(params[:project_participant])
        format.html { redirect_to @project_participant, notice: 'Project Participant was successfully created.' }
        format.json { render json: @project_participant.to_json(:include => [:project, :user, :contact]), status: :created, location: @project_participant }
      else
        format.html { render action: "new" }
        format.json { render json: @project_participant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project_participant = ProjectParticipant.find(params[:id])

    respond_to do |format|
      if @project_participant.update_attributes(params[:project_participant])
        format.html { redirect_to @project_participant, notice: 'Project Participant was successfully updated.' }
        format.json { render json: @project_participant.to_json(:include => [:project, :user, :contact]) }
      else
        format.html { render action: "edit" }
        format.json { render json: @project_participant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project_participant = ProjectParticipant.find(params[:id])
    @project_participant.destroy

    respond_to do |format|
      format.html { redirect_to project_participants_url }
      format.json { head :no_content }
    end
  end
end
