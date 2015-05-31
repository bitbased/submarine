class PermalinksController < ApplicationController
  # GET /permalinks
  # GET /permalinks.json
  def index
    @permalinks = Permalink.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @permalinks }
    end
  end

  # GET /permalinks/1
  # GET /permalinks/1.json
  def show
    @permalink = Permalink.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @permalink }
    end
  end

  # GET /permalinks/new
  # GET /permalinks/new.json
  def new
    @permalink = Permalink.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @permalink }
    end
  end

  # GET /permalinks/1/edit
  def edit
    @permalink = Permalink.find(params[:id])
  end

  # POST /permalinks
  # POST /permalinks.json
  def create
    @permalink = Permalink.new(params[:permalink])

    respond_to do |format|
      if @permalink.save
        format.html { redirect_to @permalink, notice: 'Permalink was successfully created.' }
        format.json { render json: @permalink, status: :created, location: @permalink }
      else
        format.html { render action: "new" }
        format.json { render json: @permalink.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /permalinks/1
  # PUT /permalinks/1.json
  def update
    @permalink = Permalink.find(params[:id])

    respond_to do |format|
      if @permalink.update_attributes(params[:permalink])
        format.html { redirect_to @permalink, notice: 'Permalink was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @permalink.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /permalinks/1
  # DELETE /permalinks/1.json
  def destroy
    @permalink = Permalink.find(params[:id])
    @permalink.destroy

    respond_to do |format|
      format.html { redirect_to permalinks_url }
      format.json { head :no_content }
    end
  end
end
