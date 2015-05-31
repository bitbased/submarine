class ExpenseEntriesController < ApplicationController
  # GET /expense_entries
  # GET /expense_entries.json
  def index
    if params[:project_id]
      @expense_entries = ExpenseEntry.where(project_id: params[:project_id]).order(:date)
    else
      @expense_entries = ExpenseEntry.where(date: 90.days.ago..7.days.from_now).order(:date)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @expense_entries }
    end
  end

  # GET /expense_entries/1
  # GET /expense_entries/1.json
  def show
    @expense_entry = ExpenseEntry.with_deleted.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @expense_entry }
    end
  end

  # GET /expense_entries/new
  # GET /expense_entries/new.json
  def new
    @expense_entry = ExpenseEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @expense_entry }
    end
  end

  # GET /expense_entries/1/edit
  def edit
    @expense_entry = ExpenseEntry.with_deleted.find(params[:id])
  end

  # POST /expense_entries
  # POST /expense_entries.json
  def create
    @expense_entry = ExpenseEntry.new(params[:expense_entry])

    respond_to do |format|
      if @expense_entry.save
        format.html { redirect_to @expense_entry, notice: 'Expense entry was successfully created.' }
        format.json { render json: @expense_entry, status: :created, location: @expense_entry }
      else
        format.html { render action: "new" }
        format.json { render json: @expense_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /expense_entries/1
  # PUT /expense_entries/1.json
  def update
    @expense_entry = ExpenseEntry.with_deleted.find(params[:id])

    respond_to do |format|
      if @expense_entry.update_attributes(params[:expense_entry])
        format.html { redirect_to @expense_entry, notice: 'Expense entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @expense_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expense_entries/1
  # DELETE /expense_entries/1.json
  def destroy
    @expense_entry = ExpenseEntry.with_deleted.find(params[:id])
    @expense_entry.destroy

    respond_to do |format|
      format.html { redirect_to expense_entries_url }
      format.json { head :no_content }
    end
  end
end
