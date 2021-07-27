class CompaniesController < ApplicationController
  load_and_authorize_resource
  skip_before_action :logged_in_user, only: [:new, :create, :faq_company_policy, :edit_faq_company_policy, :update_faq_company_policy, :user_login_details]
  before_action :set_company, except: [:new, :filter, :create, :index, :faq_company_policy, :edit_faq_company_policy, :update_faq_company_policy, :user_login_details]

  # GET /companies
  # GET /companies.json
  def index
    set_companies
  end

  def filter
    set_companies
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    @employee_titles = EmployeeTitle.all.map{|e| e.display_name}
  end

  # GET /companies/new
  def new
    @company = Company.new
    # build 1 user
    @company.users.build
  end

  # GET /companies/1/edit
  def edit
  end

  # GET /team/1
  # GET /teams/1.json
  def managers
    @title = 'Managers'
    @users = @company.managers
    @users = @users.page params[:page]
    @user_images = User.get_images(@users)
    render 'users/index'
  end

  def employees
    @title = 'Employees'

    respond_to do |format|
      format.html do
        @users = @company.employees.page params[:page]
        @user_images = User.get_images(@users)
        render 'users/index'
      end
      format.js do
        @users = @company.employees.page params[:page]
        @user_images = User.get_images(@users)
        render 'users/index'
      end
      format.csv do
        @users = @company.employees_for_export
        headers['Content-Disposition'] = "attachment; filename=\"" +
          @company.name + " - #{@title}.csv\""
        headers['Content-Type'] ||= 'text/csv'
        render 'users/index'
      end
    end
  end

  def user_login_details
    @users = User.where(archived: false)
  end

  def faq_company_policy
    @company = Company.find(1)
  end

  def edit_faq_company_policy
    @company = Company.find(1)
  end

  def update_faq_company_policy
    @company = Company.find(1)
    @company.update_attributes(faq_company_policy: params[:faq_company_policy])
    respond_to do |format|
      format.html { redirect_to faq_company_policy_path }
    end
  end

  # POST /companies
  # POST /companies.json
  def create
    @saved = false
    log_out if logged_in?
    Company.transaction do
      @company = Company.new(company_params)
      @company.save
      @company_admin = @company.users[0]
      @company_admin.make_company_admin
      @company_admin.send_activation_email
      @company_admin.approve
      @company_admin.save
      @saved = true
    end

    if @saved
      flash[:success] = 'Company was successfully created. Please check your email to activate your account.'
      redirect_to root_url
    else
      render 'new'
    end

  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    respond_to do |format|
      file = params[:company].delete("file")

      if @company.update(company_params)
        if !file.blank?
          @company.image = Image.create(file: file)
        end
        flash[:success] = 'Company was successfully updated.'
        # TODO: make environment editable
        #@company.update_agent_types
        #@company.update_employee_titles
        format.html { redirect_to @company }
        format.json { render :show, status: :ok, location: @company }
      else
        format.html { render :edit }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company.archive
    set_companies
    respond_to do |format|
      flash[:success] = 'Company was successfully destroyed.'
      format.html { redirect_to companies_url }
      format.json { head :no_content }
    end
  end

  def destroy_image
    if @company.image
      @company.image = nil
    end
    respond_to do |format|
      format.js
    end
  end

  protected

    def correct_stale_record_version
      @company.reload
      params[:company].delete('lock_version')
   end

  private
    def set_company
      @company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "Sorry, that company is not active"
      redirect_to action: 'index'
    end

    def set_companies
      @companies = Company.search(params[:search_params])
      @companies = @companies.unarchived.page params[:page]
    end

    def company_params
      params.require(:company).permit(:name, :file, :agent_types, :employee_titles,
        :privacy_policy, :terms_conditions, :website, :faq_company_policy,
        users_attributes: [:name, :email, :password, :password_confirmation])
    end
end
