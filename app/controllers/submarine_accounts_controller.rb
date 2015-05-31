class SubmarineAccountsController < LandingController

  def new
    @host_uri = request.host_with_port.downcase
    @subdomain = @host_uri.gsub(/^(?:([^\.]+)\.)?.*/,'\1')
    @submarine_account = SubmarineAccount.new(:harvest_subdomain => @subdomain, :subdomain => @subdomain)
    @submarine_account.harvest_subdomain = @subdomain
  end

  def edit
    if current_user.email == SubmarineAccount.current_account.harvest_email
      @submarine_account = SubmarineAccount.current_account
    else
      redirect_to root_url, notice: 'You do not have permission to edit your Submarine account.'
    end
  end

  def update
    @submarine_account = SubmarineAccount.current_account

    respond_to do |format|
      if @submarine_account.update_attributes(params[:submarine_account])
        format.html { redirect_to root_url, notice: 'Account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @submarine_account.errors, status: :unprocessable_entity }
      end
    end
  end

  def reset
    if current_user != nil && current_user.email == SubmarineAccount.current_account.harvest_email
      ActivityLog.delete_all
      HarvestClient.delete_all
      Client.delete_all
      HarvestContact.delete_all
      Contact.delete_all
      HarvestProject.delete_all
      Project.delete_all
      HarvestTaskCategory.delete_all
      TaskCategory.delete_all
      HarvestUserAssignment.delete_all
      ProjectParticipant.delete_all
      Role.delete_all
      Task.delete_all
      HarvestTimeEntry.delete_all
      TimeEntry.delete_all
      HarvestUser.delete_all
      User.delete_all
      UserRole.delete_all
      Permalink.delete_all

      redirect_to login_url, notice: 'Account was successfully reset.'
    else
      redirect_to root_url, notice: 'You are not authorized to reset this account.'
    end
  end

  def create
    @submarine_account = SubmarineAccount.new(params[:submarine_account])

    respond_to do |format|
      if HarvestHook.authenticate(@submarine_account.harvest_subdomain, @submarine_account.harvest_email, @submarine_account.harvest_password) && @submarine_account.save
        format.html { redirect_to root_path, notice: 'Submarine Account successfully created.' }
        format.json { render json: @submarine_account, status: :created }
      else
        format.html { render action: "new" }
        format.json { render json: @submarine_account.errors, status: :unprocessable_entity }
      end
    end

  end

end