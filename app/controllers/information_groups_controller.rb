class InformationGroupsController < ApplicationController
  # GET /information_groups
  # GET /information_groups.json
  def index
    @information_groups = InformationGroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @information_groups }
    end
  end

  # GET /information_groups/1
  # GET /information_groups/1.json
  def show
    @information_group = InformationGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @information_group }
    end
  end

  # GET /information_groups/new
  # GET /information_groups/new.json
  def new
    @information_group = InformationGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @information_group }
    end
  end

  # GET /information_groups/1/edit
  def edit
    @information_group = InformationGroup.find(params[:id])
  end

  # POST /information_groups
  # POST /information_groups.json
  def create
    @information_group = InformationGroup.new(params[:information_group])

    respond_to do |format|
      if @information_group.save
        format.html { redirect_to @information_group, notice: 'Information group was successfully created.' }
        format.json { render json: @information_group, status: :created, location: @information_group }
      else
        format.html { render action: "new" }
        format.json { render json: @information_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /information_groups/1
  # PUT /information_groups/1.json
  def update
    @information_group = InformationGroup.find(params[:id])

    respond_to do |format|
      if @information_group.update_attributes(params[:information_group])
        format.html { redirect_to @information_group, notice: 'Information group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @information_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /information_groups/1
  # DELETE /information_groups/1.json
  def destroy
    @information_group = InformationGroup.find(params[:id])
    @information_group.destroy

    respond_to do |format|
      format.html { redirect_to information_groups_url }
      format.json { head :no_content }
    end
  end
end
