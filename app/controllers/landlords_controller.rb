class LandlordsController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: :create
  before_action :set_landlord, except: [:index, :new, :create, :filter,
    :filter_listings, :autocomplete_landlord_code]
  autocomplete :landlord, :code, where: {archived: false}, full: true
  include KnackInterface

  # GET /landlords
  # GET /landlords.json
  def index
    respond_to do |format|
      format.html do
        set_landlords
      end
      format.js do
        set_landlords
      end
      format.csv do
        set_landlords_csv
        headers['Content-Disposition'] = "attachment; filename=\"landlords-list.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  # GET /filter
  # AJAX call
  def filter
    set_landlords
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

  # GET /landlords/1
  # GET /landlords/1.json
  def show
    set_units
  end

  # GET /landlords/new
  def new
    @landlord = Landlord.new
    @landlord.company = current_user.company
  end

  # GET /landlords/1/edit
  def edit
  end

  # POST /landlords
  # POST /landlords.json
  def create
    @landlord = Landlord.new(format_params_before_save)
    @landlord.company = current_user.company
    if @landlord.save
      Resque.enqueue(CreateLandlord, @landlord.id) # send to Knack
      # notify staff
      @landlord.send_creation_notification
      redirect_to landlord_path(@landlord)
    else
      # error
      render 'new'
    end
  end

  # PATCH/PUT /landlords/1
  # PATCH/PUT /landlords/1.json
  def update
    if !@landlord.landlord_contacts.blank?
      #abort @landlord.landlord_contacts.inspect
      count = params[:total_count_contacts].to_i - 2
      for i in 0..count
        update_name = :"name_#{i}"
        #abort update_name.inspect
        update_email = :"email_#{i}"
        update_phone = :"phone_#{i}"
        update_position = :"position_#{i}"
        if (i <= (@landlord.landlord_contacts.count - 1))
          update_landlord_cont = :"ll_contact_id_#{i}"
          @landlord_contact = LandlordContact.find(params[update_landlord_cont])
          @landlord_contact.update(name: params[update_name], email: params[update_email], phone: params[update_phone], position: params[update_position],landlord_id: params[:id])
        else
          LandlordContact.create(name: params[update_name], email: params[update_email], phone: params[update_phone], position: params[update_position],landlord_id: params[:id])
        end
      end
      count_update = @landlord.landlord_contacts.count - 1
      # for j in (count_update + 1)..count
      #   #abort j.inspect
      #   update_name = :"name_#{j}"
      #   update_email = :"email_#{j}"
      #   update_phone = :"phone_#{j}"
      #   update_position = :"position_#{j}"
      #   LandlordContact.create(name: params[update_name], email: params[update_email], phone: params[update_phone], position: params[update_position],landlord_id: params[:id])
      # end
      # for i in 0..count_update
      #   update_name = :"name_#{i}"
      #   update_email = :"email_#{i}"
      #   update_phone = :"phone_#{i}"
      #   update_position = :"position_#{i}"
      #   LandlordContact.update(name: params[update_name], email: params[update_email], phone: params[update_phone], position: params[update_position],landlord_id: params[:id])
      # end
    else
      count = params[:total_count_contacts].to_i - 2
      for i in 0..count
        update_name = :"name_#{i}"
        update_email = :"email_#{i}"
        update_phone = :"phone_#{i}"
        update_position = :"position_#{i}"
        LandlordContact.create(name: params[update_name], email: params[update_email], phone: params[update_phone], position: params[update_position],landlord_id: params[:id])
      end
    end

    if @landlord.update(format_params_before_save.merge({updated_at: Time.now}))
      Resque.enqueue(UpdateLandlord, @landlord.id) # send to Knack
      flash[:success] = "Landlord updated!"
      redirect_to landlord_path(@landlord)
    else
      render 'edit'
    end
  end

  def delete_contact
    LandlordContact.find(params[:ll_cont_id]).delete
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

  # DELETE /landlords/1
  # DELETE /landlords/1.json
  def destroy
    @landlord.archive
    set_landlords
    respond_to do |format|
      format.html { redirect_to landlords_url, notice: 'Landlord was successfully destroyed.' }
      format.json { head :no_content }
      format.js
    end
  end

  protected

   def correct_stale_record_version
      @landlord.reload
      params[:landlord].delete('lock_version')
   end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_landlord
      @landlord = Landlord.find_unarchived(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = "Sorry, that landlord is not active."
      redirect_to action: 'index'
    end

    def set_units
      if (!params[:status_listings])
        params[:status_listings] = 'active/pending'
      end
      @residential_units, @res_images, @res_bldg_images = @landlord.residential_units(params[:status_listings])
      @residential_units = @residential_units.page(params[:page])
      @commercial_units, @com_images, @com_bldg_images = @landlord.commercial_units(params[:status_listings])
      @commercial_units = @commercial_units.page(params[:page])
      @buildings = @landlord.buildings
    end

    def set_landlords
      @landlords = Landlord.search(params, current_user)
      @listing_agents = User.where(id: Landlord.all.map(&:listing_agent_id))

      @landlords = custom_sort
      @landlords = @landlords.page params[:page]
    end

    def set_landlords_csv
      @landlords = Landlord.search_csv(params, current_user)
      @landlords = custom_sort
    end

    def custom_sort
      sort_column = params[:sort_by] || "code".freeze
      sort_order = %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc".freeze
      params[:sort_by] = sort_column
      params[:direction] = sort_order
      @landlords = @landlords.order("#{sort_column} #{sort_order}".freeze)
      @landlords
    end

    def format_params_before_save
      # get the whitelisted set of params, then arrange data
      # into the right format for our model
      param_obj = landlord_params
      param_obj[:landlord].each{ |k,v| param_obj[k] = v };
      param_obj.delete("landlord")

      param_obj
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def landlord_params
      params.permit(:sort_by, :filter, :page, :agent_filter, :status, :rating, :status_listings, :street_number,
         :route, :neighborhood, :sublocality, :administrative_area_level_2_short,
        :administrative_area_level_1_short, :postal_code, :country_short, :lat, :lng, :place_id,
        landlord: [:lock_version, :code, :rating, :ll_public_description, :ll_importance, :name, :contact_name, :mobile, :office_phone, :fax,
          :email, :website, :formatted_street_address, :notes, :accepts_third_party_gaurantor,
          :listing_agent_percentage, :listing_agent_id, :is_this_a_myspacenyc_house_listing, :point_of_contact_id,
          :has_fee, :op_fee_percentage, :tp_fee_percentage, :back_to_owner, :myspacenyc_percentage,
          :management_info, :key_pick_up_location, :update_source ])
    end
end
