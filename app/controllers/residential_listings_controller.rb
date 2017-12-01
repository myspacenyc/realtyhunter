class ResidentialListingsController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: :create
  before_action :set_residential_listing, only: [:show, :edit, :duplicate_modal, :duplicate,
    :mark_app_submitted, :update, :delete_modal, :destroy,
    :inaccuracy_modal, :send_inaccuracy, :refresh_images, :refresh_documents]
  autocomplete :building, :formatted_street_address, full: true
  autocomplete :landlord, :code, full: true
  include KnackInterface

  def index
    respond_to do |format|
      format.html.phone do
        set_residential_listings
      end
      # tablets get treated the same as desktops
      format.html.desktop do
        set_residential_listings
      end
      format.js do
        set_residential_listings
      end
      format.csv do
        set_residential_listings_csv
        headers['Content-Disposition'] = "attachment; filename=\"" +
          current_user.name + " - Residential Listings.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  # AJAX call
  def filter
    set_residential_listings
    respond_to do |format|
      format.js
      format.html do
        # catch-all
        redirect_to residential_listings_url
      end
    end
  end

  def show
  end

  def new
    @residential_unit = ResidentialListing.new
    @residential_unit.unit = Unit.new
    if params[:building_id]
      building = Building.find(params[:building_id])
      @residential_unit.unit.building_id = building.id
    end
    @buildings = current_user.company.buildings
        .where(archived: false)
        .order("formatted_street_address ASC")
        .collect {|b| [b.street_address, b.id]}
    @panel_title = "Add a listing"
  end

  def edit
    @buildings = current_user.company.buildings
        .where(archived: false)
        .order("formatted_street_address ASC")
        .collect {|b| [b.street_address, b.id]}
    @panel_title = "Edit listing"
  end

  def create
    new_unit = nil
    ResidentialListing.transaction do
      new_unit = Unit.new(residential_listing_params[:unit])
      r_params = residential_listing_params
      r_params.delete('unit')
      @residential_unit = ResidentialListing.new(r_params)
      @residential_unit.unit = new_unit
    end

    if !new_unit.available_by?
      new_unit.available_by = Date.today
    end

    if new_unit.save && @residential_unit.save
      # keep track of whether this listing just came on or off the market
      is_now_active = @residential_unit.unit.status == 'active'
      Resque.enqueue(CreateResidentialListing, @residential_unit.id, is_now_active) # send to Knack
      redirect_to @residential_unit
    else
      @buildings = current_user.company.buildings
        .where(archived: false)
        .order("formatted_street_address ASC")
        .collect {|b| [b.street_address, b.id]}
      render 'new'
    end
  end

  # GET
  # handles ajax call. uses latest data in modal
  def duplicate_modal
    respond_to do |format|
      format.js
    end
  end

  # POST
  # handles ajax call. uses latest data in modal
  def duplicate
    residential_unit_dup = @residential_unit.duplicate(
      residential_listing_params[:unit][:building_unit],
      residential_listing_params[:include_photos])

    if residential_unit_dup.valid?
      @residential_unit = residential_unit_dup
      # keep track of whether this listing just came on or off the market
      is_now_active = @residential_unit.unit.status == 'active'
      Resque.enqueue(CreateResidentialListing, @residential_unit.id, is_now_active) # send to Knack
      render js: "window.location.pathname = '#{residential_listing_path(@residential_unit)}'"
    else
      @buildings = current_user.company.buildings
        .where(archived: false)
        .order("formatted_street_address ASC")
        .collect {|b| [b.street_address, b.id]}
      # TODO: not sure how to handle this best...
      flash[:warning] = "Duplication failed!"
      respond_to do |format|
        format.js
      end
    end
  end

  def mark_app_submitted
    @residential_unit.unit.mark_app_submitted(current_user, 'residential', 'pending')
    @residential_unit.set_rented_date
    set_residential_listings
    flash[:info] = 'Application submitted on ' +
      @residential_unit.unit.building.street_address + ' and announcement sent!'
    redirect_to request.referer
  end

  # sends listings info to clients
  def send_listings
    recipients = residential_listing_params[:recipients].split(/[\,,\s]/)
    sub = residential_listing_params[:title]
    msg = residential_listing_params[:message]
    listing_ids = residential_listing_params[:listing_ids].split(',')
    ResidentialListing.send_listings(current_user.id, listing_ids, recipients, sub, msg)

    respond_to do |format|
      format.js { flash[:success] = "Email sent!" }
    end
  end

  def print_private
    ids = params[:listing_ids].split(',')
    @neighborhood_group = ResidentialListing.listings_by_neighborhood(current_user, ids)

    render pdf: current_user.company.name + ' - Private Listings - ' + Date.today.strftime("%b%d%Y"),
      template: "/residential_listings/print_private.pdf.erb",
      orientation: 'Landscape',
      layout:   "/layouts/pdf_layout.html"
  end

  def print_public
    ids = params[:listing_ids].split(',')
    @neighborhood_group = ResidentialListing.listings_by_neighborhood(current_user, ids)

    render pdf: current_user.company.name + ' - Public Listings - ' + Date.today.strftime("%b%d%Y"),
      template: "/residential_listings/print_public.pdf.erb",
      orientation: 'Landscape',
      layout:   "/layouts/pdf_layout.html"
  end

  def update
    exit
    unit_updated = nil
    listing_updated = nil
    is_now_active = nil
    # ResidentialListing.transaction do
      if @residential_unit.unit.primary_agent_id != residential_listing_params[:unit][:primary_agent_id].to_i
        Unit.update_primary_agent(
            residential_listing_params[:unit][:primary_agent_id],
            @residential_unit.unit.primary_agent_id,
            @residential_unit.unit.listing_id)
      end

      # keep track of whether this listing just came on or off the market
      if @residential_unit.unit.status != residential_listing_params[:unit][:status] &&
          residential_listing_params[:unit][:status] != 'pending'
        is_now_active = residential_listing_params[:unit][:status] == 'active'
      end

      # update fields on the unit first, then update fields on the residential_listing
      unit_updated = @residential_unit.unit.update(
          residential_listing_params[:unit].merge({updated_at: Time.now}))
      r_params = residential_listing_params
      r_params.delete('unit')
      listing_updated = @residential_unit.update(r_params.merge({updated_at: Time.now}))
    # end
    # update res
    if unit_updated && listing_updated
      Resque.enqueue(UpdateResidentialListing, @residential_unit.id, is_now_active) # send to Knack
      flash[:success] = "Unit successfully updated!"
      redirect_to residential_listing_path(@residential_unit)
    else
      @buildings = current_user.company.buildings
        .where(archived: false)
        .order("formatted_street_address ASC")
        .collect {|b| [b.street_address, b.id]}
      render 'edit'
    end
  end

  # GET
  # handles ajax call. uses latest data in modal
  def delete_modal
    @params_copy = params
    @params_copy.delete('action')
    @params_copy.delete('controller')
    @params_copy.delete('id')
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @residential_unit.archive
    set_residential_listings
    respond_to do |format|
      format.html { redirect_to residential_listings_url,
          notice: 'Residential unit was successfully destroyed.' }
      format.json { head :no_content }
      format.js
    end
  end

  # PATCH
  # triggers email to staff notifying them of the inaccuracy
  def send_inaccuracy
    if !residential_listing_params[:inaccuracy_description].blank? ||
        params[:price_drop_request]
      @residential_unit.send_inaccuracy_report(current_user,
          residential_listing_params[:inaccuracy_description],
          params[:price_drop_request])
      flash[:success] = "Report submitted! Thank you."
    end
    respond_to do |format|
      format.html { redirect_to @residential_unit }
      format.js { }
    end
  end

  # GET
  # ajax call
  def refresh_documents
    respond_to do |format|
      format.js
    end
  end

  # GET /refresh_images
  # ajax call
  def refresh_images
    respond_to do |format|
      format.js
    end
  end

  def fee_options
    building = Building.find(params[:building_id])
    if building
      @landlord = building.landlord
    end
    respond_to do |format|
      format.js
    end
  end

  def update_announcements
    @announcement_items = Announcement.search({limit: params[:limit]})
  end

  # uses different template, so must be separated into it's own function
  def update_announcements_mobile
    @announcement_items = Announcement.search({limit: params[:limit]})
  end

  def assign_modal
    @listings = ResidentialListing.joins(:unit)
      .where("units.listing_id IN (?)", params[:listing_ids])
    respond_to do |format|
      format.js
    end

  end

  def assign
    @listings = ResidentialListing.joins(:unit)
      .where("units.listing_id IN (?)", params[:listing_ids].split(" "))
    @agent = User.find(params[:primary_agent_id])

    if @agent && @listings.length > 0
      @listings.each do |l|
        if l.unit.primary_agent_id != @agent.id
          Unit.update_primary_agent(l.unit.primary_agent_id, @agent.id, l.unit.listing_id)
          l.unit.update_attribute(:primary_agent_id, @agent.id)
        end
      end

      flash[:success] = "Primary agent successfully assigned!"
    end

    params.delete('listing_ids')
    params.delete('primary_agent_id')
    set_residential_listings
    respond_to do |format|
      format.js
    end
  end

  def unassign_modal
    @listings = ResidentialListing.joins(:unit)
      .where("units.listing_id IN (?)", params[:listing_ids])
    respond_to do |format|
      format.js
    end

  end

  def unassign
    listings = ResidentialListing.joins(:unit)
      .where("units.listing_id IN (?)", params[:listing_ids].split(" "))

    if listings.length > 0
      listings.each do |l|
        Unit.update_primary_agent(l.unit.primary_agent_id, nil, l.unit.listing_id)
        l.unit.update_attribute(:primary_agent_id, nil)
        l.unit.update_attribute(:primary_agent2_id, nil)
      end

      flash[:success] = "Primary agent successfully removed!"
    end

    params.delete('listing_ids')
    set_residential_listings
    respond_to do |format|
      format.js
    end
  end

  def check_in_options
    @check_in_listings = ResidentialListing.get_check_in_options(
        params[:current_location], params[:distance])
    respond_to do |format|
      format.js
    end
  end

  def check_in
    return unless params[:listing_id]

    unit = Unit.where('units.listing_id = ?', params[:listing_id]).first
    if unit
      unit.checkins << Checkin.create!(user: current_user)
    end

    head :ok#, content_type: "text/html" #render no output
  end

  protected

    def correct_stale_record_version
      @residential_unit.reload
      @buildings = current_user.company.buildings
        .where(archived: false)
        .order("formatted_street_address ASC")
        .collect {|b| [b.street_address, b.id]}
      params[:residential_listing]. delete('lock_version')
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_residential_listing
      @residential_unit = ResidentialListing.find_unarchived(params[:id])
      if @residential_unit
        @similar_listings = @residential_unit.find_similar
      else
        flash[:warning] = "Sorry, that listing is not active."
        redirect_to action: 'index'
      end
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "Sorry, that listing is not active."
      redirect_to action: 'index'
    end

    def set_residential_listings
      @neighborhoods = Neighborhood.unarchived
          .where(state: current_user.office.administrative_area_level_1_short)
          .to_a
          .group_by(&:borough)
      @building_amenities = BuildingAmenity.where(company: current_user.company)
      @unit_amenities = ResidentialAmenity.where(company: current_user.company)

      do_search
      @bldg_images = Building.get_bldg_images_from_units(@residential_units)
      @res_images = ResidentialListing.get_images(@residential_units)
      custom_sort

      # display all found listings on the map
      @map_infos = ResidentialListing.set_location_data(
          @residential_units.to_a, @res_images, @bldg_images)

      # only get data + images for paginated responses
      @residential_units = @residential_units.page params[:page]
      if request.variant != ":phone"
        @favorite_units = @residential_units.where(favorites: true)
      end

      # convert params back into something the form can recognize
      if !params[:bed_min].blank? && params[:bed_min] == 0
        params[:bed_min] = 'Studio/Loft'
      end
      if !params[:bed_max].blank? && params[:bed_max] == 0
        params[:bed_max] = 'Studio/Loft'
      end
    end

    # returns all data for export
    def set_residential_listings_csv
      @residential_units = ResidentialListing.export_all(current_user, params)
      @utilities = Building.get_utilities(@residential_units)
      @amenities = ResidentialListing.get_amenities(@residential_units)
      @reverse_statuses = {
        '0': 'Active',
        '1': 'Pending',
        '2': 'Off'}
      @residential_units = custom_sort
    end

    def do_search
      # first, fix up parameters and set some view variables

      # default to searching for active units
      if !params[:status]
        params[:status] = "active".freeze
      end
      # parse neighborhood ids into strings for display in the view
      @selected_neighborhoods = []
      if params[:neighborhood_ids]
        neighborhood_ids = params[:neighborhood_ids].split(",").select{|i| !i.empty?}
        @selected_neighborhoods = Neighborhood.where(id: neighborhood_ids)
      end
      # parse feature ids into strings for display in the view
      @unit_features = []
      if params[:unit_feature_ids]
        feature_ids = params[:unit_feature_ids].split(",").select{|i| !i.empty?}
        @unit_features = ResidentialAmenity.where(id: feature_ids)
      end

      @bldg_features = []
      if params[:building_feature_ids]
        building_feature_ids = params[:building_feature_ids].split(",").select{|i| !i.empty?}
        @bldg_features = BuildingAmenity.where(id: building_feature_ids)
      end

      @residential_units = ResidentialListing.search(params, current_user, params[:building_id])

      @announcement_items = Announcement.search({limit: 4})
    end

    def custom_sort
      #puts "GOT ---#{params.inspect} #{params[:sort_by]} --- #{params[:direction]}---"
      sort_column = params[:sort_by] || "updated_at".freeze
      sort_order = %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc".freeze
      params[:sort_by] = sort_column
      params[:direction] = sort_order
      if sort_column == 'bed_and_baths_sorter'.freeze
        @residential_units = @residential_units.order("beds #{sort_order}, baths #{sort_order}".freeze)
      else
        @residential_units = @residential_units.order("#{sort_column} #{sort_order}".freeze)
      end
      @residential_units
    end

    def residential_listing_params
      data = params[:residential_listing].permit(
        :lock_version,
        :id,
        :recipients, :title, :message, :listing_ids, :listing_id,
        :tenant_occupied,
        :beds, :baths, :notes, :description, :lease_start, :lease_end,
        :include_photos, :inaccuracy_description,
        :has_fee, :op_fee_percentage, :tp_fee_percentage,
        :available_starting, :available_before, :custom_amenities,
        :roomsharing_filter, :unassigned_filter, :tenant_occupied_filter, :streeteasy_filter,
        :no_description,:no_images,
        :primary_agent_id, :favorites, :show,
        :expose_address, :floor, :total_room_count, :condition, :showing_instruction,
        :commission_amount, :cyof, :rented_date, :rlsny, :share_with_brokers,
        :rls_flag, :streeteasy_flag,
        unit: [:building_unit, :rent, :available_by, :access_info, :status,
          :exclusive, :building_id, :primary_agent_id, :listing_agent_id,
          :syndication_status, :has_stock_photos, :is_exclusive_agreement_signed,
          :exclusive_agreement_expires_at, :public_url,
          open_houses_attributes: [:day, :start_time, :end_time, :_destroy, :id] ],
        residential_amenity_ids: []
        )

      if data[:unit]
        if data[:unit][:status]
          data[:unit][:status] = data[:unit][:status].downcase
        end

        # convert into a datetime obj
        if !data[:unit][:available_by].blank?
          begin
            data[:unit][:available_by] = Date::strptime(data[:unit][:available_by], "%m/%d/%Y")
          rescue
            data[:unit].delete(:available_by)
          end
        end

        if data[:unit][:open_houses_attributes]
          data[:unit][:open_houses_attributes].each do |idx, oh_data|
            begin
              oh_data[:day] = Date::strptime(oh_data[:day], "%m/%d/%Y")
            rescue
            end
          end
        end
      end

      if !data[:has_fee].nil?
        if data[:has_fee] == "1".freeze
          data[:has_fee] = true
        else
          data[:has_fee] = false
        end
      end
      
      if data[:total_room_count].blank?
        data[:total_room_count] = (data[:beds].to_i + 2)
      end

      if !data[:include_photos].nil?
        if data[:include_photos] == "1".freeze
          data[:include_photos] = true
        else
          data[:include_photos] = false
        end
      end

      if !data[:description].blank?
        data[:description] = data[:description].gsub(/&nbsp;/, ' ')
      end

      data
    end
end
