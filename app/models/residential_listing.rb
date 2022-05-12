class ResidentialListing < ApplicationRecord
  audited except: [:created_at, :updated_at, :knack_id]

  queue = :residential_listings
  has_and_belongs_to_many :residential_amenities
  has_many :roommates
  has_many :rooms
  has_many :tenant_infos, dependent: :destroy
  belongs_to :rental_term
  belongs_to :unit, touch: true
  has_many :streeteasy_counters
  has_one :photo_grapher_to_do
  accepts_nested_attributes_for :unit #, allow_destroy: true
  before_save :process_custom_amenities
  after_commit :update_building_counts, :trim_audit_log

  scope :active, ->{
    joins([unit: :building])
    .where('units.status = ?', Unit.statuses["active"])
    .where('units.archived = false')
    .where('buildings.archived = false')
  }

  # scope :pending, ->{
  #   joins(:unit)
  #   .where('units.status = ?', Unit.statuses["pending"])
  #   .where('units.archived = false')
  # }
  # scope :off_market, ->{
  #   joins(:unit)
  #   .where('units.status = ?', Unit.statuses["off"])
  #   .where('units.archived = false')
  # }

  attr_accessor :include_photos, :inaccuracy_description,
    :pet_policy_shorthand, :available_starting, :available_before, :custom_amenities

	validates :lease_start, presence: true, length: {maximum: 5}
  #validates :lease_end, presence: true, length: {maximum: 5}

	validates :beds, presence: true, numericality: { less_than_or_equal_to: 11 }
	validates :baths, presence: true, numericality: { less_than_or_equal_to: 11 }

  validates :op_fee_percentage, allow_blank: true, length: {maximum: 3}, numericality: { only_integer: true }
  validates_inclusion_of :op_fee_percentage, in: 0..100, allow_blank: true

  validates :tp_fee_percentage, allow_blank: true, length: {maximum: 3}, numericality: { only_integer: true }
  validates_inclusion_of :tp_fee_percentage, in: 0..100, allow_blank: true

  # validates :total_room_count, presence: true
  
  def archive
    self.unit.archived = true
    self.unit.save
  end

  def self.find_unarchived(id)
    ResidentialListing.joins(unit: [building: [:landlord]])
      .where(id: id)
      .where('units.archived = false')
      .first
  end

  # used as a sorting condition
  def street_address_and_unit
    output = ""
     # calling from 'show', for example with full objects loaded
    if !self.respond_to? :street_number
      if unit.building.street_number
        output = unit.building.street_number + ' ' + unit.building.route
      end

      if unit.building_unit && !unit.building_unit.empty?
        output = output + ' #' + unit.building_unit
      end
    else # otherwise, we used a select statement to cherry pick fields
      if street_number
        output = street_number + ' ' + route
      end

      if !building_unit.blank?
        output = output + ' #' + building_unit
      end
    end

    output
  end

  def street_address
    output = "".freeze
     # calling from 'show', for example with full objects loaded
    if !self.respond_to? :street_number
      #if unit.building.street_number
        output = "#{unit.building.street_number} #{unit.building.route}".freeze
      #end

    else # otherwise, we used a select statement to cherry pick fields
      #if street_number
        output = "#{street_number} #{route}".freeze
      #end
    end

    output
  end

  def amenities_to_s
    amenities = residential_amenities.map{|a| a.name.titleize}
    amenities ? amenities.join(", ") : "None".freeze
  end

  def all_amenities_to_s
    bldg_amenities = unit.building.building_amenities.map{|a| a.name.titleize}
    amenities = residential_amenities.map{|a| a.name.titleize}
    amenities.concat(bldg_amenities)
    amenities ? amenities.join(", ") : "None".freeze
  end

  # list - list of residential_listings
  # returns the first image for each unit - thumbnail styles only
  def self.get_images(list)
    return nil if list.nil?

    unit_ids = list.pluck(:unit_id)
    imgs = Image.where(unit_id: unit_ids, priority: 0)
    Hash[imgs.map {|img| [img.unit_id, img.file.url(:thumb)]}]
  end

  def self.listings_by_neighborhood(user, listing_ids)
    running_list = ResidentialListing.joins(unit: {building: [:company, :landlord]})
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .where('companies.id = ?', user.company_id)
      .where('units.listing_id IN (?)', listing_ids)
      .select('buildings.formatted_street_address',
        'buildings.id AS building_id', 'buildings.street_number', 'buildings.route',
        'buildings.lat', 'buildings.lng', 'units.id AS unit_id',
        'units.building_unit', 'units.status','units.rent', 'residential_listings.beds',
        'buildings.street_number || \' \' || buildings.route as street_address_and_unit',
        'residential_listings.id', 'residential_listings.baths','units.access_info',
        'residential_listings.has_fee', 'residential_listings.updated_at',
        'neighborhoods.name AS neighborhood_name', 'neighborhoods.id AS neighborhood_id',
        'landlords.code',
        'landlords.id AS landlord_id',
        'units.available_by')
      .to_a.group_by(&:neighborhood_name)
    running_list
  end

  def self.listings_by_id(user, listing_ids)
    running_list = ResidentialListing.joins(unit: {building: [:company, :landlord]})
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .where('companies.id = ?', user.company_id)
      .where('units.listing_id IN (?)', listing_ids)
      .select('buildings.formatted_street_address',
        'buildings.id AS building_id', 'buildings.street_number', 'buildings.route',
        'buildings.lat', 'buildings.lng', 'units.id AS unit_id',
        'units.building_unit', 'units.status','units.rent', 'residential_listings.beds',
        'buildings.street_number || \' \' || buildings.route as street_address_and_unit',
        'residential_listings.id', 'residential_listings.baths','units.access_info',
        'residential_listings.has_fee', 'residential_listings.updated_at',
        'neighborhoods.name AS neighborhood_name', 'neighborhoods.id AS neighborhood_id',
        'landlords.code',
        'landlords.id AS landlord_id',
        'units.available_by', 'units.public_url')
    running_list
  end

  def self.export_all(user, params=nil)
    # if params
    #   params = params.symbolize_keys
    # end
    running_list = ResidentialListing.joins(unit: [building: [:company, :landlord]])
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .joins('left join users on users.id = units.primary_agent_id')
      .where('units.archived = false')
      .where('companies.id = ?', user.company_id)
      .select('buildings.formatted_street_address',
        'units.listing_id','units.featured', 'units.building_unit', 'units.status','units.rent', 'units.archived',
        'units.available_by', 'units.public_url', 'units.access_info', 'units.exclusive', 'units.gross_price', 'units.promotional_price',
        'units.id AS unit_id', 'units.primary_agent_id', 'units.has_stock_photos', 'units.streeteasy_primary_agent_id',
        'buildings.id AS building_id', 'buildings.street_number', 'buildings.route', 'buildings.point_of_contact',
        'buildings.lat', 'buildings.lng', 'buildings.rating',
        'residential_listings.id',
        'residential_listings.beds', 'residential_listings.baths', 'residential_listings.notes', 'residential_listings.tenant_credit_offered',
        'residential_listings.description', 'residential_listings.lease_start', 'residential_listings.dimensions', 'residential_listings.streeteasy_featured',
        'residential_listings.lease_end', 'residential_listings.has_fee', 'residential_listings.youtube_video_url',
        'residential_listings.private_youtube_url', 'residential_listings.tour_3d', 'residential_listings.streeteasy_url',
        'residential_listings.op_fee_percentage','residential_listings.tp_fee_percentage', 'residential_listings.bonus_details',
        'residential_listings.tenant_occupied', 'residential_listings.created_at', 'residential_listings.alt_address',
        'residential_listings.updated_at','residential_listings.streeteasy_flag', 'residential_listings.streeteasy_flag_one','residential_listings.show',
        'neighborhoods.name AS neighborhood_name', 'neighborhoods.id AS neighborhood_id',
        'landlords.code', 'landlords.rating', 'landlords.listing_agent_id',
        'landlords.id AS landlord_id',
        'users.name')

    running_list = ResidentialListing._filter_query(running_list, user, params)
    running_list
  end

  # takes in a hash of search options
  # can be formatted_street_address, landlord
  # status, unit, bed_min, bed_max, bath_min, bath_max, rent_min, rent_max,
  # neighborhoods, has_outdoor_space, features, pet_policy, ...
  def self.search(params, user, building_id=nil)
    running_list = ResidentialListing.joins(unit: {building: [:company, :landlord]})
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .joins('left join users on users.id = units.primary_agent_id')
      .where('units.archived = false')
      .where('companies.id = ?', user.company_id)
      .select('buildings.formatted_street_address',
        'buildings.id AS building_id', 'buildings.street_number', 'buildings.route','buildings.point_of_contact',
        'buildings.lat', 'buildings.lng', 'buildings.rating', 'buildings.streeteasy_eligibility', 'units.id AS unit_id', 'units.promotional_price',
        'units.building_unit','units.featured', 'units.status','units.rent', 'residential_listings.beds','residential_listings.claim_for_naked_apartment',
        'residential_listings.claim_for_individual_syndication_page','residential_listings.renthop', 'residential_listings.streeteasy_featured',
        'units.primary_agent_id',  'units.has_stock_photos', 'units.primary_agent_for_rs',
        'buildings.street_number || \' \' || buildings.route as street_address_and_unit', 'residential_listings.dimensions', 'residential_listings.tenant_credit_offered',
        'residential_listings.id', 'residential_listings.baths','units.access_info', 'units.gross_price', 'residential_listings.notes',
        'residential_listings.favorites','residential_listings.streeteasy_flag_one', 'residential_listings.lease_start', 'residential_listings.private_bathroom',
        'residential_listings.streeteasy_flag', 'residential_listings.streeteasy_claim', 'residential_listings.couples_accepted',
        'residential_listings.has_fee', 'residential_listings.created_at', 'residential_listings.updated_at', 'residential_listings.youtube_video_url', 'residential_listings.private_youtube_url',
        'residential_listings.tenant_occupied', 'residential_listings.roomshare_department', 'residential_listings.tour_3d', 'residential_listings.bonus_details',
        'residential_listings.photographer_update_date','residential_listings.photographer_user_id', 'residential_listings.pending_se', 'residential_listings.managed_listing',
        'residential_listings.roomfill', 'residential_listings.partial_move_in', 'residential_listings.working_this_listing', 'residential_listings.alt_address',
        'residential_listings.virtual_tours_available', 'residential_listings.in_person_tours_available', 'residential_listings.no_access_until_vacant',
        'neighborhoods.name AS neighborhood_name', 'neighborhoods.id AS neighborhood_id',
        'landlords.code', 'landlords.rating', 'landlords.ll_importance', 'landlords.listing_agent_id',
        'landlords.id AS landlord_id', 'units.third_tier', 'landlords.accepts_third_party_gaurantor',
        'units.listing_id', 'units.available_by', 'units.public_url', 'units.exclusive',
        'users.name').order('units.building_unit asc')
      #abort running_list.inspect
    if !params && !building_id
      running_list
    elsif !params && building_id
      running_list = running_list.where(building_id: building_id)
    else
      running_list = ResidentialListing._filter_query(running_list, user, params)
    end
  end

  def self._filter_query(running_list, user, params)
    if !params
      return running_list
    end

    params.delete('controller'.freeze)
    params.delete('action'.freeze)
    params.delete('format'.freeze)

    # only admins are allowed to view off-market units
    # can_view_off_market = user.is_management? ||
    #     user.is_listings_manager? ||
    #     user.is_photo_manager?
    # if !can_view_off_market
    #  running_list = running_list.where.not('status = ?', Unit.statuses['off'])
    # end

    # all search params come in as strings from the url
    # clear out any invalid search params
    params.delete_if{ |k,v| (!v || v == 0 || v.empty?) }

    # search by address (building)
    if params[:address]
      # cap query string length for security reasons
      address = params[:address][0, 500]
      running_list =
       running_list.where('buildings.formatted_street_address ILIKE ? OR residential_listings.alt_address ILIKE ?', "%#{address}%", "%#{address}%" )
    end

    if params[:alt_address]
      address = params[:alt_address][0, 500]
      running_list =
       running_list.where('residential_listings.alt_address ILIKE ?', "%#{address}%" )
    end

    # search by unit
    if params[:unit]
      # cap query string length for security reasons
      address = params[:unit][0, 50]
      running_list = running_list.where("building_unit ILIKE ?", "%#{params[:unit]}%")
    end

    if params[:alt_unit]
      address = params[:alt_unit][0, 50]
      running_list = running_list.where("units.streeteasy_unit ILIKE ?", "%#{params[:alt_unit]}%")
    end


    # search by status
    if params[:status]
      status = params[:status].downcase
      included = ['active/pending', 'active', 'pending', 'off', 'rented', 'rsonly', 'rsonly/active'].include?(status)
      if included
        if status == 'active/pending'
          running_list = running_list.where("status = ? or status = ?",
            Unit.statuses["active"], Unit.statuses["pending"])
        elsif status == 'rsonly/active'
          running_list = running_list.where("status = ? or status = ?",
            Unit.statuses["active"], Unit.statuses["rsonly"])
        elsif status == "off"
            running_list = running_list.where("status = ?",
            Unit.statuses["off"]).limit(300)
        elsif status == "rented"
            running_list = running_list.where("status = ?",
            Unit.statuses["rented"]).limit(300)
        else
          running_list = running_list.where("status = ?", Unit.statuses[status])
        end
      end
    end

    if params[:public_url]
      running_list = running_list.where("units.public_url =?", params[:public_url])
    end

    if params[:ll_importance]
      if params[:ll_importance] == "gold"
        running_list = running_list.where("landlords.ll_importance =?", "gold")
      elsif params[:ll_importance] == "silver"
        running_list = running_list.where("landlords.ll_importance =?", "silver")
      elsif params[:ll_importance] == "bronze"
        running_list = running_list.where("landlords.ll_importance =?", "bronze")
      else
        running_list = running_list
      end
    end

    # search by rent
    if params[:rent_min] && params[:rent_max]
      rent_min = params[:rent_min].to_i
      rent_max = params[:rent_max].to_i
      running_list = running_list.where("rent >= ? AND rent <= ?", rent_min, rent_max)
    elsif params[:rent_min] && !params[:rent_max]
      rent_min = params[:rent_min].to_i
      running_list = running_list.where("rent >= ?", rent_min)
    elsif !params[:rent_min] && params[:rent_max]
      rent_max = params[:rent_max].to_i
      running_list = running_list.where("rent <= ?", rent_max)
    end

    if params[:net_min] && params[:net_max]
      net_min = params[:net_min].to_i
      net_max = params[:net_max].to_i
      running_list = running_list.where("rent >= ? AND rent <= ?", net_min, net_max)
    elsif params[:net_min] && !params[:net_max]
      net_min = params[:net_min].to_i
      running_list = running_list.where("rent >= ?", net_min)
    elsif !params[:net_min] && params[:net_max]
      net_max = params[:net_max].to_i
      running_list = running_list.where("rent <= ?", net_max)
    end

    if params[:gross_min] && params[:gross_max]
      gross_min = params[:gross_min].to_i
      gross_max = params[:gross_max].to_i
      running_list = running_list.where("gross_price >= ? AND gross_price <= ?", gross_min, gross_max)
    elsif params[:gross_min] && !params[:gross_max]
      gross_min = params[:gross_min].to_i
      running_list = running_list.where("gross_price >= ?", gross_min)
    elsif !params[:gross_min] && params[:gross_max]
      gross_max = params[:gross_max].to_i
      running_list = running_list.where("gross_price <= ?", gross_max)
    end

    # search beds
    # clean up search terms first
    params.delete('bed_min') if params[:bed_min] == 'Any'
    params.delete('bed_max') if params[:bed_max] == 'Any'
    if !params[:bed_min].blank?
      if params[:bed_min].downcase == 'studio/loft'
        params[:bed_min] = 0
      end
      running_list = running_list.where("beds >= ?", params[:bed_min])
    end
    if !params[:bed_max].blank?
      if params[:bed_max].downcase == 'studio/loft'
        params[:bed_max] = 0
      end
      running_list = running_list.where("beds <= ?", params[:bed_max])
    end

    # search baths
    params.delete('bath_min') if params[:bath_min] == 'Any'
    params.delete('bath_max') if params[:bath_max] == 'Any'
    if params[:bath_min] && params[:bath_max]
      running_list = running_list.where("baths >= ? AND baths <= ?", params[:bath_min], params[:bath_max])
    elsif params[:bath_min] && !params[:bath_max]
      running_list = running_list.where("baths >= ?", params[:bath_min])
    elsif !params[:bath_min] && params[:bath_max]
      running_list = running_list.where("baths <= ?", params[:bath_max])
    end

    #Search Parent Neighborhoods
    if params[:parent_neighborhoods]
      neighborhood_ids = params[:parent_neighborhoods][0, 256]
      neighborhoods = neighborhood_ids.split(",").select{|i| !i.strip.empty?}
      if neighborhoods.length > 0 # ignore empty selection
        running_list = running_list
         .where('neighborhood_id IN (?)', neighborhoods)
      end
    end

    # search neighborhoods
    if params[:neighborhood_ids]
      neighborhood_ids = params[:neighborhood_ids][0, 256]
      neighborhoods = neighborhood_ids.split(",").select{|i| !i.strip.empty?}

      if (neighborhoods.include? "43") == true
          neighborhoods += ["6", "5"]
      end

      if (neighborhoods.include? "14") == true
        neighborhoods << "15"
      end

      if (neighborhoods.include? "52") == true
        neighborhoods << "26"
      end

      if (neighborhoods.include? "9") == true
        neighborhoods << "53"
      end
      if neighborhoods.length > 0 # ignore empty selection
        running_list = running_list
         .where('neighborhood_id IN (?)', neighborhoods)
      end
    end

    if params[:train_line]
      train_line = params[:train_line]
      if train_line == "0"
        running_list = running_list
      else
        bldg_ids = Building.joins(:trains).where('train_id =?', train_line).pluck(:id)
        running_list = running_list.where("buildings.id IN (?)", bldg_ids)
      end
    end

    if params[:building_feature_ids]
      features = params[:building_feature_ids][0, 256]
      features = features.split(",").select{|i| !i.empty?}
        bldg_ids = Building.joins(:building_amenities).where('building_amenity_id IN (?)', features).pluck(:id)
        running_list = running_list.where("building_id IN (?)", bldg_ids)
    end

    # search landlord code
    if params[:landlord]
      running_list = running_list.where("code ILIKE ?", "%#{params[:landlord]}%")
    end

    if params[:listing_id]
      running_list = running_list.where("units.listing_id = ?", params[:listing_id].to_i)
    end

    # search pet policy mobile
    if params[:pet_policy_shorthand_mobile]
      pp = params[:pet_policy_shorthand_mobile].downcase
      policies = nil
      if pp == "no pets"
        policies = PetPolicy.where(name: "no pets", company: user.company)
      elsif pp == "cats only"
        policies = PetPolicy.where(name: "cats only", company: user.company)
      elsif pp == "dogs only"
        policies = PetPolicy.where(name: "dogs only", company: user.company)
      elsif pp == "case by case"
        policies = PetPolicy.where(name: "case by case", company: user.company)
      elsif pp == "cats/small dogs"
        policies = PetPolicy.where(name: "case by case", company: user.company)
      elsif pp == "monthly pet fee"
        policies = PetPolicy.where(name: "monthly pet fee", company: user.company)
      elsif pp == "pet deposit required"
        policies = PetPolicy.where(name: "pet deposit required", company: user.company)
      elsif pp == "pets allowed"
        policies = PetPolicy.where(name: "pets allowed", company: user.company)
      elsif pp == "pets ok"
        policies = PetPolicy.where(name: "pets ok", company: user.company)
      elsif pp == "pets upon approval"
        policies = PetPolicy.where(name: "pets upon approval", company: user.company)
      elsif pp == "small pets ok (<30 lbs)"
        policies = PetPolicy.where(name: "small pets ok (<30 lbs)", company: user.company)    
      end

      if policies
        running_list = running_list#.joins(building: :pet_policy)
          .where('pet_policy_id IN (?)', policies.ids)
      end
    end

    # search pet policy
    if params[:pet_policy_shorthand]
      # pp = params[:pet_policy_shorthand].downcase
      # policies = nil
      # if pp == "none"
      #   policies = PetPolicy.where(name: "no pets", company: user.company)
      # elsif pp == "cats only"
      #   policies = PetPolicy.policies_that_allow_cats(user.company, true)
      # elsif pp == "dogs only"
      #   policies = PetPolicy.policies_that_allow_dogs(user.company, true)
      # end

      # if policies
      #   running_list = running_list#.joins(building: :pet_policy)
      #     .where('pet_policy_id IN (?)', policies.ids)
      # end
      policies = params[:pet_policy_shorthand][0, 256]
      policies = policies.split(",").select{|i| !i.empty?}
      if policies.include?("19")
        policies << "5" << "7"
      end
      if policies
        running_list = running_list#.joins(building: :pet_policy)
          .where('pet_policy_id IN (?)', policies)
      end
    end

    if !params[:available_starting].blank?
      running_list = running_list.where('available_by > ?', params[:available_starting]);
    end
    if !params[:available_before].blank?
      running_list = running_list.where('available_by < ?', params[:available_before]);
    end

    # search by brokers fee
    if params[:has_fee]
      has_fee = params[:has_fee].downcase
      included = %w[yes no].include?(has_fee)
      if included
        running_list = running_list.where(has_fee: has_fee == "yes")
      end
    end

    if params[:parent_building_amenities]
      features = params[:parent_building_amenities][0, 256]
      features = features.split(",").select{|i| !i.empty?}
        bldg_ids = Building.joins(:building_amenities).where('building_amenity_id IN (?)', features).pluck(:id)
        running_list = running_list.where("building_id IN (?)", bldg_ids)
    end



    if params[:parent_amenities]
      features = params[:parent_amenities][0, 256]
      features = features.split(",").select{|i| !i.empty?}
      # if features.include? "145"
      #   features += ["89", "118", "128", "142", "132", "90", "131", "2"]
      # end
      # if features.include? "146"
      #   features += ["5", "84", "3", "4", "103", "106"]
      # end
      # if features.include? "147"
      #   features += ["100", "75", "105", "134", "14", "140", "73", "120", "71", "96", "15", "16", "20"]
      # end
      # if features.include? "148"
      #   features += ["87", "125", "6", "129", "112", "70", "76", "82", "77", "127", "72", "117", "8", "101", "102", "122", "9", "86"]
      # end
      # if features.include? "149"
      #   features += ["123", "113", "92", "135", "85", "88", "91", "95", "99", "126", "116", "98", "18", "81", "144", "1"]
      # end
      # if features.include? "150"
      #   features += ["83", "143", "97", "141", "139"]
      # end
      # if features.include? "151"
      #   features += ["119", "11", "12", "68", "114", "130"]
      # end
      # if features.include? "152"
      #   features += ["115", "110", "69", "78", "124", "109", "7", "94", "121", "79", "80", "17", "19"]
      # end
      # if features.include? "153"
      #   features += ["104", "133", "108"]
      # end
      # if features.include? "154"
      #   features += ["136", "137", "138"]
      # end
      running_list = running_list.joins(:residential_amenities)
        .where('residential_amenity_id IN (?)', features)
    end

    # search features
    if params[:unit_feature_ids]
      # sanitize input
      features = params[:unit_feature_ids][0, 256]
      features = features.split(",").select{|i| !i.empty?}
      if features.include? "145"
        features += ["89", "118", "128", "142", "132", "90", "131", "2"]
      end
      if features.include? "146"
        features += ["5", "84", "3", "4", "103", "106"]
      end
      if features.include? "147"
        features += ["100", "75", "105", "134", "14", "140", "73", "120", "71", "96", "15", "16", "20"]
      end
      if features.include? "148"
        features += ["87", "125", "6", "129", "112", "70", "76", "82", "77", "127", "72", "117", "8", "101", "102", "122", "9", "86"]
      end
      if features.include? "149"
        features += ["123", "113", "92", "135", "85", "88", "91", "95", "99", "126", "116", "98", "18", "81", "144", "1"]
      end
      if features.include? "150"
        features += ["83", "143", "97", "141", "139"]
      end
      if features.include? "151"
        features += ["119", "11", "12", "68", "114", "130"]
      end
      if features.include? "152"
        features += ["115", "110", "69", "78", "124", "109", "7", "94", "121", "79", "80", "17", "19"]
      end
      if features.include? "153"
        features += ["104", "133", "108"]
      end
      if features.include? "154"
        features += ["136", "137", "138"]
      end
      running_list = running_list.joins(:residential_amenities)
        .where('residential_amenity_id IN (?)', features)
    end

    # roomsharing only
    if params[:roomsharing_filter] == 'true'
      # roomsharing apartments are defined as 'apartments with 3+ bedrooms'
      #running_list = running_list.where(for_roomsharing: true)
      running_list = running_list.where('beds >= 3');
    end

    # unassigned listings only
    if params[:unassigned_filter] == 'true'
      running_list = running_list.where(
        'units.primary_agent_id IS NULL AND units.primary_agent2_id IS NULL')
    end

    if !params[:tenant_occupied].blank?
      if params[:tenant_occupied] == "0"
        running_list = running_list.where('residential_listings.tenant_occupied = ?', true)
      elsif params[:tenant_occupied] == "1"
        running_list = running_list.where('residential_listings.tenant_occupied = ?', false)
      else
        running_list = running_list
      end
          
    end

    if !params[:youtube_video_url].blank?
      if params[:youtube_video_url] == "0"
        running_list = running_list.where("residential_listings.youtube_video_url != ''" )
      elsif params[:youtube_video_url] == "1"
        running_list = running_list.where("residential_listings.youtube_video_url = ''")
      else
        running_list = running_list
      end
          
    end
    
    if !params[:private_youtube_video_url].blank?
      if params[:private_youtube_video_url] == "0"
        running_list = running_list.where("residential_listings.private_youtube_url != ''" )
      elsif params[:private_youtube_video_url] == "1"
        running_list = running_list.where("residential_listings.private_youtube_url = ''")
      else
        running_list = running_list
      end
          
    end

    if !params[:tour_3d].blank?
      if params[:tour_3d] == "0"
        running_list = running_list.where("residential_listings.tour_3d != ''" )
      elsif params[:tour_3d] == "1"
        running_list = running_list.where("residential_listings.tour_3d = ''")
      else
        running_list = running_list
      end
          
    end

    if !params[:has_stock_photos_filter].blank?
      running_list = running_list.where(
          'units.has_stock_photos = ?', params[:has_stock_photos_filter])
    end

    if !params[:roomfill].blank?
      running_list = running_list.where(
          'residential_listings.roomfill = ?', params[:roomfill])
    end

    if !params[:working].blank?
      running_list = running_list.where(
          'residential_listings.working_this_listing = ?', params[:working])
    end
    
    if !params[:couples_accepted].blank?
      running_list = running_list.where(
          'residential_listings.couples_accepted = ?', params[:couples_accepted])
    end

    if !params[:private_bathroom].blank?
      running_list = running_list.where('residential_listings.private_bathroom =?', params[:private_bathroom])
    end

    if !params[:partial_move_in].blank?
      running_list = running_list.where(
          'residential_listings.partial_move_in = ?', params[:partial_move_in])
    end

    if !params[:exclusive_filter].blank?
      running_list = running_list.where(
          'units.exclusive = ?', params[:exclusive_filter])
    end

    if params[:no_description] == 'true'
      running_list = running_list.where("length(residential_listings.description) < 20")
    end

    if !params[:third_tier].blank?
      running_list = running_list.where("units.third_tier =?", params[:third_tier])
    end

    if !params[:pending_se].blank?
      running_list = running_list.where("residential_listings.pending_se =?", params[:pending_se])
    end

    if !params[:managed_listing].blank?
      running_list = running_list.where("residential_listings.managed_listing =?", params[:managed_listing])
    end

    if !params[:tenant_credit_offered].blank?
      running_list = running_list.where("residential_listings.tenant_credit_offered =?", params[:tenant_credit_offered])
    end

    if !params[:past_24_hours_active].blank?
      running_list = running_list.where("residential_listings.created_at >= ?", (Time.now - 1.day).strftime("%m/%d/%Y"))
    end

    if !params[:featured].blank?
      running_list = running_list.where("units.featured =?", params[:featured])
    end

    if params[:no_images] == 'true'
        less_two = Unit.joins(:images).group("units.id").having("count(units.id)<3")
        find_less_two = less_two.all.map(&:id)
        nil_rec = Unit.includes(:images).where(images: { unit_id: nil })
        find_nil = nil_rec.all.map(&:id)
        unit_id_collect = find_less_two + find_nil
        #abort find_all_collect.inspect
        # all_unit = Unit.all
        # unit_id_collect = []
        # all_unit.each do |each_unit|
        #   if each_unit.images.count <= 2
        #     if each_unit.images.blank?
        #       unit_id_collect << each_unit.id
        #     else
        #       unit_id_collect << each_unit.images.first.unit_id
        #     end
        #   end
        # end
        running_list = running_list.where("unit_id IN (?)", unit_id_collect)
        # abort running_list.all.map(&:id).length.inspect
        # running_list = running_list.select { |list_item| list_item.unit.images.distinct.count < 2 }
        # #running_list = ResidentialListing.where(id: running_list.map(&:id))
        # abort running_list.class.inspect
        # abort ResidentialListing.where(id: running_list.map(&:id)).inspect
    end

    # primary agent
    if !params[:primary_agent_id].blank?
      running_list = running_list.where('units.primary_agent_id = ? OR units.primary_agent2_id = ?',
        params[:primary_agent_id], params[:primary_agent_id])
    end

    if !params[:listing_agent_id].blank?
      running_list = running_list.where('landlords.listing_agent_id =?', params[:listing_agent_id])
    end

    if !params[:primary_agent_for_rs].blank?
      running_list = running_list.where('units.primary_agent_for_rs = ?', params[:primary_agent_for_rs])
    end
    
    if !params[:claim_agent_id].blank?
      running_list = running_list.where(["residential_listings.claim_for_naked_apartment @> ?", "{#{params[:claim_agent_id]}}"])
    end

    if !params[:point_of_contact].blank?
      running_list = running_list.where('buildings.point_of_contact = ?',params[:point_of_contact])
    end

    if !params[:streeteasy_filter].blank?
      if params[:streeteasy_filter] == 'Yes'
        running_list = running_list.where('residential_listings.streeteasy_flag = TRUE')
        # running_list = running_list.where('units.exclusive = TRUE')
        #   .where("residential_listings.description <> ''")
        #   .where('units.status IN (?) OR units.syndication_status = ?',
        #       [Unit.statuses["active"], Unit.statuses["pending"]],
        #       Unit.syndication_statuses['Force syndicate'])
        #   .where('units.primary_agent_id > 0')
        #   .where('units.syndication_status IN (?)', [
        #       Unit.syndication_statuses['Syndicate if matches criteria'],
        #       Unit.syndication_statuses['Force syndicate']
        #     ])
        #   .where('residential_listings.streeteasy_flag = TRUE')
      elsif params[:streeteasy_filter] == 'No'
        running_list = running_list.where('residential_listings.streeteasy_flag = FALSE')
        #running_list = running_list.where('units.exclusive = FALSE')
        #running_list = running_list.where("residential_listings.description = ''")
      end
    end

    # if !params[:building_rating].blank?
    #   rating = params[:building_rating]
    #   if rating == "0"
    #     running_list = running_list.where("buildings.rating =?", 1)
    #   # elsif rating == "1"
    #   #   running_list = running_list.where("buildings.rating =?", 1)
    #   # elsif rating == "2"
    #   #   running_list = running_list.where("buildings.rating =?", 2)
    #   # elsif rating == "3"
    #   #   running_list = running_list.where("buildings.rating =?", 3)
    #   elsif rating == "1"
    #     running_list = running_list.where("buildings.rating IN (?)", [0,2,3])
    #   else
    #     running_list = running_list
    #   end
    # end

    if !params[:streeteasy_eligibility].blank?
      rating = params[:streeteasy_eligibility]
      if rating == "0"
        running_list = running_list.where("buildings.streeteasy_eligibility =?", 0)
      # elsif rating == "1"
      #   running_list = running_list.where("buildings.rating =?", 1)
      # elsif rating == "2"
      #   running_list = running_list.where("buildings.rating =?", 2)
      # elsif rating == "3"
      #   running_list = running_list.where("buildings.rating =?", 3)
      elsif rating == "1"
        running_list = running_list.where("buildings.streeteasy_eligibility =?", 1)
      else
        running_list = running_list
      end
    end

    if !params[:accepts_third_party_gaurantor].blank?
      if params[:accepts_third_party_gaurantor] == "0"
        running_list = running_list.where("landlords.accepts_third_party_gaurantor =?", true)
      elsif params[:accepts_third_party_gaurantor] == "1"
        running_list = running_list.where("landlords.accepts_third_party_gaurantor =?", false)
      else
        running_list = running_list
      end
    end

    if !params[:landlord_rating].blank?
      rating = params[:landlord_rating]
      if rating == "0"
        running_list = running_list.where("landlords.rating =?", 0)
      elsif rating == "1"
        running_list = running_list.where("landlords.rating =?", 1)
      elsif rating == "2"
        running_list = running_list.where("landlords.rating =?", 2)
      elsif rating == "3"
        running_list = running_list.where("landlords.rating =?", 3)
      else
        running_list = running_list
      end
    end

    if !params[:streeteasy_claim].blank?
      #abort params[:streeteasy_claim].inspect
      if params[:streeteasy_claim] == 'Yes'
        #abort running_list.inspect
        running_list = running_list.where('residential_listings.streeteasy_claim = TRUE')
      elsif params[:streeteasy_claim] == 'No'
        #abort running_list.inspect
        running_list = running_list.where('residential_listings.streeteasy_claim = FALSE AND residential_listings.streeteasy_flag_one = TRUE')
      end
    end

    # ts = ["35", "428", "39", "146"]
    # running_list = running_list.where.not('buildings.point_of_contact IN (?)', ts)

    running_list
  end

  def deep_copy_imgs(dst_id)
    @dst = ResidentialListing.find(dst_id)
    # deep copy photos
    self.unit.images.each { |i|
      img_copy = Image.new
      img_copy.file = i.file
      img_copy.unit_id = @dst.unit.id
      img_copy.save
      @dst.unit.images << img_copy
    }
    @dst.save!
  end

  def duplicate(new_unit_num, new_streeteasy_unit_num, include_photos=false)
    if new_unit_num && new_unit_num != self.id
      # copy objects
      unit_dup = self.unit.dup
      unit_dup.building_unit = new_unit_num
      unit_dup.streeteasy_unit = new_streeteasy_unit_num
      unit_dup.listing_id = nil
      unit_dup.rent = 0
      unit_dup.access_info = nil
      unit_dup.maths_free = nil
      if unit_dup.save!

        residential_unit_dup = self.dup
        residential_unit_dup.update(unit_id: unit_dup.id, knack_id: nil, youtube_video_url: nil, tour_3d: nil, private_youtube_url: nil,notes: nil, dimensions: "", streeteasy_url: nil, tenant_credit_offered: false)

        self.residential_amenities.each {|a|
          residential_unit_dup.residential_amenities << a
        }
      else
        raise "Error saving unit"
      end

      if include_photos
        self.deep_copy_imgs(residential_unit_dup.id)
        residential_unit_dup.unit.update(has_stock_photos: true)
      else
        residential_unit_dup.unit.update(has_stock_photos: false)
      end

      #Image.async_copy_residential_unit_images(self.id, residential_unit_dup.id)
      # if include_photos
      #   self.deep_copy_imgs(residential_unit_dup.id)
      # end

      #puts "NEW UNIT NUM #{residential_unit_dup.unit.building_unit}"
      #update_building_counts
      residential_unit_dup
    else
      raise "No unit number, invalid unit number, or unit number already taken specified"
    end
  end

  def self.send_listings(source_agent_id, listing_ids, recipients, sub, msg)
    if source_agent_id
      UnitMailer.send_residential_listings(source_agent_id, listing_ids,
          recipients, sub, msg).deliver!
    else
      "No sender specified"
    end
  end

  def send_inaccuracy_report(reporter, message, feedback_category, photo_error_types)
    if reporter && (!message.blank? || feedback_category || photo_error_types)
      Feedback.create!({
        user_id: reporter.id,
        unit_id: self.id,
        description: message,
        feedback_category: feedback_category,
        photo_error_type: photo_error_types
      })
      UnitMailer.inaccuracy_reported(self.id, reporter.id, message, feedback_category, photo_error_types).deliver!
      UnitMailer.feedback_report_notifaction(reporter.id).deliver!
    else
      raise "Invalid params specified while sending feedback"
    end
  end

  def send_inaccuracy_report_room(reporter, message, feedback_category, photo_error_types)
      if reporter && (!message.blank? || feedback_category || photo_error_types)
        Feedback.create!({
          user_id: reporter.id,
          unit_id: self.id,
          description: message,
          feedback_category: feedback_category,
          photo_error_type: photo_error_types
        })
        UnitMailer.inaccuracy_reported_room(self.id, reporter.id, message, feedback_category, photo_error_types).deliver!
        UnitMailer.feedback_report_notifaction(reporter.id).deliver!
      else
        raise "Invalid params specified while sending feedback"
      end
  end

  def take_off_market(new_lease_end_date)
    if new_lease_end_date
      self.unit.update({status: :off, available_by: new_lease_end_date})
    else
      raise "No lease end date specified"
    end
  end

  # def calc_lease_end_date
  #   end_date = Date.today
  #   end_date = Date.today >> 12
  #   end_date
  # end

  # collect the data we will need to access from our giant map view
  def self.set_location_data(runits, images, bldg_images)
    map_infos = {}
    # speed optimizaiton. `while true` is faster than 'for ...'
    i = 0
    while true
      if i == runits.length
        break
      end

      runit = runits[i]

      if runit.street_number
        street_address = "#{runit.street_number} #{runit.route}".freeze
      else
        street_address = runit.route
      end
      #room_info = []
      #a = 0
      # runit.rooms.each do |room|
      #   room_info = [{ id: (runit.rooms[a].id if !runit.rooms[a].blank?),
      #     status: (runit.rooms[a].status if !runit.rooms[a].blank?),
      #     name: (runit.rooms[a].name if !runit.rooms[a].blank?),
      #     rent: (runit.rooms[a].rent if !runit.rooms[a].blank?)}]
      #   room_info + room_info
      # end
      # rooms_info = runit.rooms.all.collect {|u| [u.id, u.status, u.name, u.rent]}.inspect
      # rooms_info = {
      #   room_info: room_info
      # }
      # runit.rooms.each do |room|
      #   room_info = [{ id: (runit.rooms[i].id if !runit.rooms[i].blank?),
      #     status: (runit.rooms[i].status if !runit.rooms[i].blank?),
      #     name: (runit.rooms[i].name if !runit.rooms[i].blank?),
      #     rent: (runit.rooms[i].rent if !runit.rooms[i].blank?)}]
      #   room_info + room_info
      # end
      # a = runit.rooms.map{|x| [{:id => x.id,:status => x.status, :name => x.name, :rent => x.rent}]}.flatten
      # abort a.inspect
      # abort room_info.inspect
      bldg_info = {
        building_id: runit.building_id,
        lat: runit.lat,
        lng: runit.lng,
        working_this_listing: (runit.working_this_listing if !runit.available_by.nil?)
      }
      unit_info = {
        id: runits[i].id,
        building_unit: runit.building_unit,
        beds: runit.beds,
        baths: runit.baths,
        rent: runit.rent,
        gross: runit.unit.gross_price,
        avail: (runit.available_by.strftime("%b %d") if !runit.available_by.blank?),
        public_url: runit.public_url,
        public_url_for_room: runit.unit.public_url_for_room
        }
      room_info = {
        a: runit.rooms.order(name: :asc).map{|x| [{:id => x.id,:status => x.status, :name => x.name, :rent => x.rent}]}.flatten
      }
      # rooms_info = {}
      # if !runit.rooms.blank?
      #   runit.rooms.each do |room|
      #     room_info = {
      #       id: room.id,
      #       status: room.status,
      #       name: room.name,
      #       rent: room.rent
      #     }
      #     abort room_info.inspect
      #     rooms_info += room_info
      #   end
      #   abort rooms_info.inspect
      # end

      if bldg_images[runit.building_id]
        unit_info['image'] = bldg_images[runit.building_id]
      elsif images[runit.unit_id]
        unit_info['image'] = images[runit.unit_id]
      end

      if map_infos.has_key?(street_address)
        map_infos[street_address]['units'] << unit_info
        map_infos[street_address]['rooms'] << room_info
      else
        bldg_info['units'] = [unit_info]
        bldg_info['rooms'] = [room_info]
        map_infos[street_address] = bldg_info
      end

      i += 1
    end

    map_infos.to_json
  end

  def self.for_buildings(bldg_ids, status=nil)
    listings = ResidentialListing.joins(unit: {building: :landlord})
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .joins('left join users on users.id = units.primary_agent_id')
      .where('buildings.id in (?)', bldg_ids)
      .where('units.archived = false')
      .select('buildings.formatted_street_address',
        'buildings.id AS building_id', 'buildings.street_number', 'buildings.route',
        'units.building_unit','units.featured', 'units.status','units.rent', 'units.id AS unit_id',
        'units.has_stock_photos', 'units.primary_agent_for_rs', 'residential_listings.notes', 'residential_listings.private_bathroom', 'residential_listings.tenant_credit_offered',
        'residential_listings.beds', 'residential_listings.id', 'residential_listings.lease_start', 'residential_listings.dimensions',
        'residential_listings.streeteasy_flag', 'residential_listings.streeteasy_flag_one', 'units.gross_price', 'units.promotional_price',
        'residential_listings.baths','units.access_info', 'residential_listings.renthop', 'residential_listings.couples_accepted','residential_listings.streeteasy_featured',
        'residential_listings.has_fee', 'residential_listings.updated_at', 'residential_listings.youtube_video_url', 'residential_listings.private_youtube_url',
        'residential_listings.tenant_occupied', 'residential_listings.roomshare_department', 'residential_listings.tour_3d', 'residential_listings.alt_address',
        'residential_listings.roomfill', 'residential_listings.partial_move_in', 'residential_listings.working_this_listing', 'residential_listings.bonus_details',
        'residential_listings.photographer_user_id','residential_listings.photographer_update_date', 'residential_listings.pending_se', 'residential_listings.managed_listing',
        'residential_listings.virtual_tours_available', 'residential_listings.in_person_tours_available', 'residential_listings.no_access_until_vacant',
        'neighborhoods.name AS neighborhood_name',
        'landlords.code', 'landlords.ll_importance', 'landlords.accepts_third_party_gaurantor', 'landlords.listing_agent_id',
        'landlords.id AS landlord_id', 'units.third_tier', 'units.public_url',
        'units.primary_agent_id', 'units.available_by', 'units.listing_id', 'units.exclusive',
        'users.name')
      .order('residential_listings.updated_at desc')

    if !status.nil?
      status_lowercase = status.downcase
      if status_lowercase != 'any'
        if status_lowercase == 'active/pending'
          listings = listings
              .where("units.status IN (?) ",
                [Unit.statuses['active'], Unit.statuses['pending']])
        else
          listings = listings
              .where("units.status = ? ", Unit.statuses[status_lowercase])
        end
      end
    end

    images = ResidentialListing.get_images(listings)
    bldg_images = Building.get_bldg_images_from_units(listings)
    return listings, images, bldg_images
  end

  def self.for_units(unit_ids, status=nil)
    listings = ResidentialListing.joins(unit: {building: [:landlord]})
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .joins('left join users on users.id = units.primary_agent_id')
      .where('units.id in (?)', unit_ids)
      .where('units.archived = false')
      .select('buildings.formatted_street_address',
        'buildings.id AS building_id', 'buildings.street_number', 'buildings.route',
        'units.building_unit','units.featured', 'units.status','units.rent', 'units.id AS unit_id',
        'units.has_stock_photos', 'units.primary_agent_for_rs', 'units.gross_price', 'residential_listings.notes', 'units.promotional_price',
        'residential_listings.beds', 'residential_listings.id', 'residential_listings.lease_start', 'residential_listings.dimensions', 'residential_listings.streeteasy_featured',
        'residential_listings.baths','units.access_info', 'residential_listings.streeteasy_flag', 'residential_listings.private_bathroom',
        'residential_listings.streeteasy_flag_one', 'residential_listings.renthop', 'residential_listings.couples_accepted', 'residential_listings.bonus_details',
        'residential_listings.has_fee', 'residential_listings.updated_at', 'residential_listings.youtube_video_url', 'residential_listings.private_youtube_url',
        'residential_listings.tenant_occupied', 'residential_listings.roomshare_department', 'residential_listings.tour_3d', 'residential_listings.alt_address',
        'residential_listings.roomfill', 'residential_listings.partial_move_in', 'residential_listings.working_this_listing', 'residential_listings.tenant_credit_offered',
        'residential_listings.photographer_user_id','residential_listings.photographer_update_date', 'residential_listings.pending_se', 'residential_listings.managed_listing',
        'residential_listings.virtual_tours_available', 'residential_listings.in_person_tours_available', 'residential_listings.no_access_until_vacant',
        'neighborhoods.name AS neighborhood_name',
        'landlords.code', 'landlords.ll_importance', 'landlords.accepts_third_party_gaurantor', 'landlords.listing_agent_id',
        'landlords.id AS landlord_id', 'units.third_tier', 'units.public_url',
        'units.primary_agent_id', 'units.available_by', 'units.listing_id', 'units.exclusive',
        'users.name')

    if !status.nil?
      status_lowercase = status.downcase
      if status_lowercase != 'any'
        if status_lowercase == 'active/pending'
          listings = listings
              .where("units.status IN (?) ",
                [Unit.statuses['active'], Unit.statuses['pending']]).distinct
        else
          listings = listings
              .where("units.status = ? ", Unit.statuses[status_lowercase]).distinct
        end
      end
    end

    images = ResidentialListing.get_images(listings)
    bldg_images = Building.get_bldg_images_from_units(listings)
    return listings, images, bldg_images
  end

  # Used in our API. Takes in a list of units
  def self.get_amenities(list_of_units)
    unit_ids = list_of_units.pluck('units.id')
    list = ResidentialListing.joins(:residential_amenities)
      .where(unit_id: unit_ids).select('name', 'unit_id', 'id')
      .to_a.group_by(&:unit_id)
  end

  def can_roomshare
    # puts "can_roomshare #{beds} #{unit.status} #{unit.status == Unit.statuses['pending']}"
    if self.respond_to?(:status)
      beds >= 3 && self.status == Unit.statuses['pending']
    else
      beds >= 3 && unit.status == Unit.statuses['pending']
    end
  end

  def self.to_csv(user, params)
    listings = ResidentialListing.export_all(user, params)
    agents = Unit.get_primary_agents(listings)
    reverse_statuses = {'0': 'Active', '1': 'Pending', '2': 'Off'}

    attributes = [
      'Full Address', 'Unit', 'Neighborhood', 'Is Exclusive?', 'Roomsharing OK?',
      'Beds', 'Baths', 'Notes', 'Description', 'Lease Start', 'Lease End',
      'Has Fee?', 'OP Fee Percentage', 'TP Fee Percentage', 'Tenant Occupied',
      'Primary Agent', 'Listing ID', 'Landlord', 'Price', 'Available', 'Access',
      'Status', 'Created At', 'Updated At', 'Archived']

    CSV.generate(headers: true) do |csv|
      csv << attributes

      listings.each do |listing|
        csv << [listing.formatted_street_address, listing.building_unit, listing.neighborhood_name,
          listing.exclusive ? 'Yes' : 'No', listing.can_roomshare ? 'Yes' : 'No',
          listing.beds, listing.baths, listing.notes, listing.description, listing.lease_start,
          listing.lease_end,
          listing.has_fee ? 'Yes' : 'No', listing.op_fee_percentage, listing.tp_fee_percentage,
          listing.tenant_occupied ? 'Yes' : 'No',
          agents[listing.unit_id] ? agents[listing.unit_id].pluck(:name).join(', ') : '',
          listing.listing_id,
          listing.code,
          listing.rent,
          listing.available_by, listing.access_info,
          reverse_statuses[listing.status.to_s.to_sym],
          listing.created_at, listing.updated_at, listing.archived ? 'Yes' : 'No']
      end
    end
  end

  def set_rented_date
    self.rented_date = Date.today
    self.save
  end

  def self.get_check_in_options(current_position, max_distance)
    return unless current_position
    return unless max_distance

    max_distance = max_distance.to_i
    buildings = Building.joins(:units)
        .where('units.archived = false')
        .where('buildings.archived = false')
        .where("status = ?", Unit.statuses["active"])

    buildings = buildings.select{|b| b.distanceTo(current_position) < max_distance}

    listings = ResidentialListing.joins([unit: :building])
        .where('units.archived = false')
        .where('buildings.archived = false')
        .where("status = ?", Unit.statuses["active"])
        .where('buildings.id IN (?)', buildings.map(&:id))
        .select(
          'residential_listings.id',
          'buildings.street_number || \' \' || buildings.route || \' #\' || units.building_unit as full_address',
          'units.listing_id')
    listings
  end

  def find_similar
    similar_listings = ResidentialListing.active
        .where(beds: self.beds)
        .where(baths: self.baths)
        .where("buildings.neighborhood_id = ?", self.unit.building.neighborhood_id)
        .where('residential_listings.id != ?', self.id)

    criteria = ResidentialAmenity.where(name:
        ['private yard', 'doorman', 'patio', 'gym', 'roof access', 'yard', 'washer/dryer in unit'])
    matching_amenities = self.residential_amenities.where(id: criteria.pluck(:id))

    # We only match on a handful of amenities that are consider big ticket items.
    if matching_amenities.length > 0 && similar_listings && similar_listings.length > 1
      similar_listings = ResidentialListing.joins(:residential_amenities)
        .where('residential_amenities.id IN (?)', matching_amenities.pluck(:id))
        .where('residential_listings.id IN (?)', similar_listings.pluck(:id))
    end

    # randomize selection, and limit to 3
    # exclude ourselves
    similar_listings.distinct.sample(3)
  end

  private
    def process_custom_amenities
      if custom_amenities
        amenities = custom_amenities.split(',')
        amenities.each{|a|
          if !a.empty?
            a = a.downcase.strip
            found = ResidentialAmenity.where(name: a, company: self.unit.building.company).first
            if !found
              self.residential_amenities << ResidentialAmenity.create!(name: a, company: self.unit.building.company)
            end
          end
        }
      end
    end

    def update_building_counts
      bldg = self.unit.building
      bldg.update_total_unit_count
      bldg.update_active_unit_count
      bldg.landlord.update_total_unit_count
      bldg.landlord.update_active_unit_count
    end

    def trim_audit_log
      # to keep updates speedy, we cap the audit log at 100 entries per record
      audits_count = audits.length
      if audits_count > 50
        audits.first.update(comment: 'created')
      end
    end

end
