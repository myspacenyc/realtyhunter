class BuildingsController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: :create
  before_action :set_building, except: [:index, :new, :create, :filter, :filter_listings,
    :refresh_images, :neighborhood_options, :autocomplete_building_formatted_street_address]
  autocomplete :building, :formatted_street_address, full: true

  include KnackInterface

  # GET /buildings
  # GET /buildings.json
  def index
    set_buildings

    respond_to do |format|
      format.html
      format.js
      format.csv do
        set_buildings_csv
        headers['Content-Disposition'] = "attachment; filename=\"buildings-list.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  # GET /filter_buildings
  # AJAX call
  def filter
    set_buildings
    respond_to do |format|
      format.js
    end
  end

  # AJAX call
  def filter_listings
    set_units
    respond_to do |format|
      format.js
    end
  end

  # GET /buildings/1
  # GET /buildings/1.json
  def show
    if !@building
      redirect_to buildings_url
    end
    set_units
  end

  # GET /buildings/new
  def new
    @building = Building.new
    landlord_id = params[:landlord_id]
    if landlord_id && Landlord.where("id = ?", landlord_id)
      @building.landlord_id = landlord_id
    end
    @landlords = current_user.company.landlords
      .where(archived: false)
      .order("code ASC")
      .collect {|l| [l.code, l.id]}
  end

  # GET /buildings/1/edit
  def edit
    @landlords = current_user.company.landlords
      .where(archived: false)
      .order("code ASC")
      .collect {|l| [l.code, l.id]}
  end

  # POST /buildings
  # POST /buildings.json
  def create
      # if this building has already been entered, redirect to that page
      #puts building_params[:building]
      @bldg = Building.where(
        street_number: building_params[:street_number],
        route: building_params[:route],
        archived: false
        ).first
      #puts "FOUND BLDG #{@bldg.inspect} #{building_params[:street_number]} #{building_params[:route]}"
      if @bldg
        flash[:info] = "Building already exists!"
        redirect_to @bldg
      else
        @formatted_street_address = building_params[:building][:formatted_street_address]
        bldg_params = format_params_before_save(true)
        if @building.save(bldg_params)
          Resque.enqueue(CreateBuilding, @building.id) # send to Knack
          # notify staff
          @building.send_creation_notification
          redirect_to @building
        else
          # error
          render 'new'
      end
    end
  end

  def mass_edit
    @building = Building.find(params[:id])
    if @building.units.where(status: 0, archived: false).blank? || !@building.units.where(status: 0, archived: false)[0].commercial_listing.blank?
      flash[:info] = "No Active Unit available!"
      redirect_to building_path(@building)
    else
    end
  end

  def mass_edit_update
    @building = Building.find(params[:id])
    all_id = []
    if !params["hide_on_website"].nil?
      params["hide_on_website"].each do |k,v|
        all_id << k.to_i
        unit = Unit.find(k.to_i)
        unit.update!(hide_on_website: v)
      end
    end
    
    all_active_unit = @building.units.where(status: 0).map(&:id)
    all_remain_id = all_active_unit - all_id
    all_remain_id.each do |ac_unit|
        unit = Unit.find(ac_unit)
        unit.update!(hide_on_website: false)
    end

    all_selected_units = []
    if !params[:price_cal].nil?
      params[:price_cal].each do |price_cal|
        all_selected_units << Unit.find(price_cal.to_i)
      end
    end
    if !params[:rent].nil?
      params[:rent].each do |rent|
        all_selected_units << Unit.find(rent.to_i)
      end
    end
    # @building = Building.find(params[:id])
    # @building.units.where(status: 0).each do |unit|
    i = 0
    all_selected_units.each do |unit|
      #abort params["price_cal"]["#{unit.id}"].inspect
      if !params[:price_cal].nil?
        if params["price_cal"]["#{unit.id}"] == "1"
          #if !params["rent"]["#{unit.id}"].to_i.blank?
            params[:rent] = (params["gross_price"]["#{unit.id}"].to_i * (params["lease_start"]["#{unit.id}"].to_i - params["mths_free"]["#{unit.id}"].to_f)) / params["lease_start"]["#{unit.id}"].to_i
            params[:rent] = params[:rent].round
            @price_slack_msg = "\n Unit #{i} \n #{unit.residential_listing.beds} Beds / #{unit.residential_listing.baths} Baths \n Price Changed from $#{unit.rent} to $#{params[:rent]}"
            unit.update(rent: params[:rent], gross_price: params["gross_price"]["#{unit.id}"], maths_free: params["mths_free"]["#{unit.id}"], updated_at: Time.now())
            unit.residential_listing.update(lease_start: params["lease_start"]["#{unit.id}"], lease_end: params["lease_end"]["#{unit.id}"], updated_at: Time.now())
          #end
          
        end
      end
      if !params["available_by"]["#{unit.id}"].blank?
        unit.update(available_by: Date::strptime(params["available_by"]["#{unit.id}"], "%m/%d/%Y"), updated_at: Time.now())
  @available_by_slack_msg = "\n Unit #{i} \n #{unit.residential_listing.beds} Beds / #{unit.residential_listing.baths} Baths \n Available Date Updated"
      end
      if !params["point_of_contact"]["#{unit.id}"].blank?
        @building.update(point_of_contact: params["point_of_contact"]["#{unit.id}"], updated_at: Time.now())
  @poc_slack_msg = "\n Unit #{i} \n #{unit.residential_listing.beds} Beds / #{unit.residential_listing.baths} Baths \n Point of contact Updated"
      end

      if !params["primary_agent_id"]["#{unit.id}"].blank?
        unit.update(primary_agent_id: params["primary_agent_id"]["#{unit.id}"], updated_at: Time.now())
      end
      i = i + 1
    end
    #Start Find all SE flag Checked
    all_selected_se_units = []
    if !params[:streeteasy_flag].nil?
      params[:streeteasy_flag].each do |se|
        all_selected_se_units << Unit.find(se.to_i)
      end
    end
    #End Find all SE flag Checked
    #Start Update all SE flag Checked
    all_selected_se_units.each do |unit|
      if params["streeteasy_flag"]["#{unit.id}"].present?
        unit.update(primary_agent_id: params["primary_agent_id"]["#{unit.id}"], updated_at: Time.now())
        unit.residential_listing.update(streeteasy_flag: params["streeteasy_flag"]["#{unit.id}"], updated_at: Time.now())
      end
    end

    # notifier = Slack::Notifier.new "https://hooks.slack.com/services/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" do
    #         defaults channel: "#general",
    #                  username: "notifier"
    #       end
    #       notifier.ping "*Listing* *Update* \n #{@building.street_number} #{@building.route} \n #{@building.neighborhood.name} #{@price_slack_msg if !@price_slack_msg.nil?} #{@available_by_slack_msg if !@available_by_slack_msg.nil?} #{@poc_slack_msg if !@poc_slack_msg.nil?} \n Changes made by #{current_user.name}"
    #End Update all SE flag Checked
    redirect_to building_path(params[:id])
  end

  # PATCH/PUT /buildings/1
  # PATCH/PUT /buildings/1.json
  def update
    if params[:building][:third_tier] == "1"
      if !@building.units.blank?
        @building.units.each do |unit|
          unit.update_attribute(:third_tier, true)
        end
      end
    end
    if params[:building][:third_tier] == "0"
      if !@building.units.blank?
        @building.units.each do |unit|
          unit.update_attribute(:third_tier, false)
        end
      end
    end
    if current_user.id == 505 || current_user.id == 713 || current_user.id == 112
      update_merge_col = {route: params[:building][:route],updated_at: Time.now}
    else
      update_merge_col = {updated_at: Time.now}
    end
    if @building.update(format_params_before_save(false).merge(update_merge_col))
      Resque.enqueue(UpdateBuilding, @building.id) # send to Knack
      flash[:success] = "Building updated!"
      redirect_to building_path(@building)
    else
      @landlords = current_user.company.landlords
        .where(archived: false)
        .order("code ASC")
        .collect {|l| [l.code, l.id]}
      render 'edit'
    end
  end

  # GET /refresh_images
  # ajax call
  def refresh_images
    respond_to do |format|
      format.js
    end
  end

  # GET
  # handles ajax call. uses latest data in modal
  def delete_modal
    @params_copy = params
    @params_copy.delete('action')
    @params_copy.delete('controller')
    @params_copy.delete('id')
    # puts @params_copy.inspect
    respond_to do |format|
      format.js
    end
  end

  def delete_residential_listing_modal
    @params_copy = params
    @params_copy.delete('action')
    @params_copy.delete('controller')
    @params_copy.delete('id')
    @residential_unit = ResidentialListing.find_unarchived(params[:listing_id])
    @params_copy.delete('listing_id')
    # puts @params_copy.inspect
    respond_to do |format|
      format.js {render 'residential_listings/delete_modal'}
    end
  end

  # DELETE /buildings/1
  # DELETE /buildings/1.json
  def destroy
    @building.archive
    set_buildings
    respond_to do |format|
      format.html { redirect_to buildings_url, notice: 'Building was successfully deleted.' }
      format.json { head :no_content }
      format.js
    end
  end

  # GET
  # handles ajax call. uses latest data in modal
  # def inaccuracy_modal
  #   respond_to do |format|
  #     format.js
  #   end
  # end

  # triggers email to staff notifying them of the inaccuracy
  def send_inaccuracy
    @building.send_inaccuracy_report(current_user,
        building_params[:building][:inaccuracy_description])
    flash[:success] = "Report submitted! Thank you."
    respond_to do |format|
      format.html { redirect_to @building }
      format.js {  }
    end
  end

  def neighborhood_options
    @building = Building.new
    @building.sublocality = params[:sublocality]

    respond_to do |format|
      format.js
    end
  end

  protected

   def correct_stale_record_version
      @building.reload
      params[:building].delete('lock_version')
   end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_building
      @building = Building.find_unarchived(params[:id])
      if @building.neighborhood
        @building.custom_neighborhood_id = @building.neighborhood.id
      end
    end

    def set_units
      if (!params[:status_listings])
        params[:status_listings] = 'active/pending'
      end
      @residential_units, @res_images, @res_bldg_images = @building.residential_units(params[:status_listings])
      @residential_units = @residential_units.page(params[:page])
      @commercial_units, @com_images, @com_bldg_images = @building.commercial_units(params[:status_listings])
      # puts @com_bldg_images
      @commercial_units = @commercial_units.page(params[:page])
    end

    def set_buildings_csv
      @buildings = Building.export_all(
          building_params[:filter],
          building_params[:status],
          building_params[:rating],
          building_params[:streeteasy_eligibility],
          building_params[:filter_dotsignal_code])
      @amenities = Building.get_amenities_from_buildings(@buildings)
      @utilities = Building.get_utilities_from_buildings(@buildings)
      @buildings = custom_sort
      # @buildings = _filter_query
    end

    def set_buildings
      @buildings = Building.search(
        building_params[:filter],
        building_params[:status],
        building_params[:rating],
        building_params[:streeteasy_eligibility],
        building_params[:filter_dotsignal_code])

      @buildings = custom_sort
      @buildings = @buildings.page params[:page]
      @bldg_imgs = Building.get_images(@buildings)
    end

    def custom_sort
      sort_column = building_params[:sort_by] || "formatted_street_address".freeze
      sort_order = %w[asc desc].include?(building_params[:direction]) ? building_params[:direction] : "asc".freeze
      params[:sort_by] = sort_column
      params[:direction] = sort_order
      @buildings = @buildings.order("#{sort_column} #{sort_order}".freeze)
      @buildings
    end

    def format_params_before_save(is_new)
      # get the whitelisted set of params, then arrange data
      # into the right format for our model
      param_obj = building_params
      param_obj[:building].each{ |k,v| param_obj[k] = v };

      param_obj.delete("building".freeze)
      # delete so that this field doesn't conflict with our foreign key
      @neighborhood_name = param_obj[:neighborhood]
      param_obj.delete("neighborhood".freeze)

      if is_new
        @building = Building.new(param_obj)
      end

      @building.company = current_user.company
      @building.neighborhood = @building.find_or_create_neighborhood(@neighborhood_name, param_obj[:sublocality],
        param_obj[:administrative_area_level_2_short], param_obj[:administrative_area_level_1_short])

      param_obj
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    # Need to take in additional params here. Can't rename them, or the geocode plugin
    # will not map to them correctly
    def building_params
      data = params.permit(:sort_by, :direction, :page, :filter, :status, :rating, :streeteasy_eligibility, :filter_dotsignal_code, :status_listings, :street_number,
        :route, :route_short, :intersection, :neighborhood,
        :sublocality, :administrative_area_level_2_short,
        :administrative_area_level_1_short, :inaccuracy_description, :request_price_drop,
        :postal_code, :country_short, :lat, :lng, :place_id, :landlord_id, :file,
        building: [:lock_version, :formatted_street_address, :dotsignal_code, :point_of_contact,
          :building_tag_number, :building_key_status, :building_office_location, :building_master,
          :building_commercial_property, :building_key_active, :building_signout_key, :building_case_name,
         :push_to_zumper, :building_website, :building_name, :section_8, :income_restricted, :year_build, :featured, 
         :rating, :notes, :description, :landlord_id, :user_id, :third_tier, :building_youtube_url,
          :inaccuracy_description, :pet_policy_id, :rental_term_id, :custom_rental_term, :file,
          :custom_amenities, :custom_utilities, :neighborhood_id, :neighborhood, :llc_name,
          building_amenity_ids: [], images_files: [], utility_ids: [] ])

      # this parameter was introduced later on, and we don't want to update the database field's
      # name. Instead, just transfer the param value into the field that lines up with our db.
      if !data[:route_short].blank?
        data[:route] = data[:route_short]
        data.delete('route_short')
      end

      data
    end
end
