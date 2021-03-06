class RoommatesController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: :create
  before_action :set_roommate, except: [:index, :new, :create, :filter,
    :download, :send_update, :unarchive, :unarchive_modal,
    :send_message, :delete_modal, :destroy, :get_units,
    :match_multiple, :match_multiple_modal,
    :autocomplete_user_email, :autocomplete_roommate_name,
    :autocomplete_building_formatted_street_address, :check_availability,
    :mark_read, :destroy_multiple_modal, :destroy_multiple]
  autocomplete :roommate, :name, full: true
  autocomplete :user, :email, full: true
  autocomplete :building, :formatted_street_address, full: true

  def index
    respond_to do |format|
      format.html do
        set_roommates
      end
      format.js do
        set_roommates
      end
      format.csv do
        set_roommates_csv
        headers['Content-Disposition'] = "attachment; filename=\"" +
          current_user.company.name + " - Roommates.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def filter
    set_roommates
    respond_to do |format|
      format.js
    end
  end

  # GET /residential_units/new
  def new
    @roommate = Roommate.new
  end

  # POST /residential_units
  # POST /residential_units.json
  def create
    @roommate = Roommate.new(roommate_params[:roommate])
    @roommate.user = current_user
    @roommate.company = current_user.company
    if @roommate.save
      flash[:success] = "Roomsharing referral data saved!"
      redirect_to @roommate
    else
      # error
      render 'new'
    end
  end

  def download
  	ids = params[:roommate_ids].split(',')
  	@roommates = Roommate.pull_data_for_export(ids)

  	respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"roommates-list.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
      format.pdf do
      	render pdf: current_user.company.name + ' - Roommates - ' + Date.today.strftime("%b%d%Y"),
          template: "/roommates/download.pdf.erb",
          orientation: 'Landscape',
          layout:   "/layouts/pdf_layout.html"
      end
    end
  end

  def send_message
    recipients = roommate_params[:roommate][:recipients].split(/\s, \,/)
    sub = roommate_params[:roommate][:title]
    msg = roommate_params[:roommate][:message]
    roommate_ids = roommate_params[:roommate][:ids]
    Roommate.send_message(current_user.id, recipients, sub, msg, roommate_ids.split(','))

    respond_to do |format|
      format.js { flash[:success] = "Message sent!" }
    end
  end

  def show
    @roommate = Roommate.find(params[:id])
    # once someone views this roomie, mark the record as 'read'
    @roommate.mark_read

    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "Sorry, that roommate is no longer available."
      redirect_to action: 'index'
  end

  def edit
    @roommate = Roommate.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "Sorry, that roommate is no longer available."
      redirect_to action: 'index'
  end

  def delete_modal
    @params_copy = params
    @params_copy.delete('action')
    @params_copy.delete('controller')
    @params_copy.delete('id')
    respond_to do |format|
      format.js
    end
  end

  # DELETE /residential_units/1
  # DELETE /residential_units/1.json
  def destroy
    Roommate.destroy(@roommate.id)
    set_roommates
    respond_to do |format|
      format.html { redirect_to roommates_url, notice: 'Roommate was successfully deleted.' }
      format.json { head :no_content }
      format.js
    end
  end

  def destroy_multiple_modal
    @roommates = Roommate.where(id: params[:ids]).order('name asc')
    respond_to do |format|
      format.js
    end
  end

  def destroy_multiple
    if !params[:ids].blank?
      Roommate.where(id: params[:ids]).destroy_all
      params.delete('ids')
    end
    set_roommates
    respond_to do |format|
      format.html { redirect_to roommates_url, notice: 'Roommates were successfully deleted.' }
      format.json { head :no_content }
      format.js
    end
  end

  def match_modal
    respond_to do |format|
      format.js
    end
  end

  # DELETE /residential_units/1
  # DELETE /residential_units/1.json
  def match
    if @roommate.match(params)
      set_roommates
      flash[:success] = @roommate.name + ' was successfully matched!'
      respond_to do |format|
        format.html { redirect_to roommates_url }
        format.json { head :no_content }
        format.js
      end
    else
      flash[:danger] = @roommate.name + ' could not be matched.'
    end
  end

  def match_multiple_modal
    set_roommates
    respond_to do |format|
      format.js
    end
  end

  def mark_read
    if Roommate.mark_read(params[:ids])
      params.delete('ids')
      set_roommates
      flash[:success] = 'Roommates marked as read.'
      respond_to do |format|
        format.html { redirect_to roommates_url }
        format.json { head :no_content }
        format.js
      end
    else
      set_roommates
      flash[:danger] = 'Roommates could not marked read.'
    end
  end

  # DELETE /residential_units/1
  # DELETE /residential_units/1.json
  def match_multiple
    if Roommate.match(params)
      set_roommates
      flash[:success] = 'Roommates were successfully matched!'
      respond_to do |format|
        format.html { redirect_to roommates_url }
        format.json { head :no_content }
        format.js
      end
    else
     flash[:danger] = 'Roommates could not be matched.'
    end
  end

  def unmatch_modal
    @roommate = Roommate.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def unmatch
    @roommate = Roommate.find(params[:id])
    @roommate.unarchive
    params[:status] = 'Matched'
    set_roommates
    respond_to do |format|
      format.html { redirect_to roommates_url, notice: 'Roommate was successfully unmatched.' }
      format.json { head :no_content }
      format.js
    end
  end

  def update
    if @roommate.update(roommate_params[:roommate].merge({updated_at: Time.now}))
      flash[:success] = "Profile updated!"
      redirect_to @roommate
    else
      render 'edit'
    end
  end

  def get_units
    # roomsharing units = residential listings with 3+ bedrooms
    @listings = Unit.joins(:residential_listing, :building)
      .where("buildings.formatted_street_address = ?", params[:address])
      .where("units.status = ?", Unit.statuses["active"])
      .where('residential_listings.beds >= 3')
      #.where("residential_listings.for_roomsharing = true")
    @can_proceed = @listings.count > 0
  end

  def check_availability
    @can_proceed = false
    if !params[:ids].blank? && !params[:unit_id].blank?
      listing = ResidentialListing.where(unit_id: params[:unit_id]).limit(1).first
      num_roommates = params[:ids].count + listing.roommates.count
      @can_proceed = num_roommates <= listing.beds
    end
  end

  protected

    def correct_stale_record_version
      @roommate.reload
      params[:roommate].delete('lock_version')
    end

  private
  	def set_roommate
      @roommate = Roommate.find_by!(id: params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "Sorry, that roommate was not found."
      redirect_to action: 'index'
  	end

  	def set_roommates
      @neighborhoods = Neighborhood.where(name: [
        'Bedford Stuyvesant',
        'Bushwick',
        'Crown Heights',
        'Greenpoint',
        'Prospect Lefferts Gardens',
        'Prospect Heights',
        'Ridgewood',
        'Williamsburg',
        'Flatbush Ditmas Park'])
      @referrers = current_user.company.users.unarchived.pluck(:name)
      @referrers.insert(0, 'Website')

      # set a default status if none otherwise specified
      if params[:status].blank?
        params[:status] = 'Unmatched'.freeze
      end

      @roommates = Roommate.search(params)
      @roommates = custom_sort
      @roommates = @roommates.page params[:page]
  	end

    def set_roommates_csv
      # set a default status if none otherwise specified
      if params[:status].blank?
        params[:status] = 'Unmatched'.freeze
      end

      @roommates = Roommate.export(params)
      @roommates = custom_sort
      @roommates = @roommates
    end

  	def custom_sort
      sort_column = params[:sort_by] || "submitted_date".freeze
      sort_order = %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc".freeze
      params[:sort_by] = sort_column
      params[:direction] = sort_order
      @roommates = @roommates.order("#{sort_column} #{sort_order}")
      @roommates
  	end

    def roommate_params
    	data = params.permit(:sort_by, :filter, :page, :direction, :name, :referred_by, :neighborhood_id,
        :submitted_date, :move_in_date, :monthly_budget, :status,
        :do_you_have_pets, :address,
        roommate: [:lock_version, :name, :phone_number, :internal_notes,
          :email, :how_did_you_hear_about_us, :upload_picture_of_yourself, :describe_yourself,
          :monthly_budget, :move_in_date, :neighborhood, :do_you_have_pets,
          :user_id, :recipients, :title, :message, :ids])

      if data[:roommate]
        # convert into a datetime obj
        if !data[:roommate][:move_in_date].blank?
          data[:roommate][:move_in_date] = Date::strptime(data[:roommate][:move_in_date], "%m/%d/%Y")
        end

        if !data[:roommate][:neighborhood].blank? && data[:roommate][:neighborhood] != 'Other'
          data[:roommate][:neighborhood] = Neighborhood.where(name: data[:roommate][:neighborhood]).first
        end

        data[:roommate].delete_if{|k,v| (!v || v.blank?) }
      end

      data
    end

  end
