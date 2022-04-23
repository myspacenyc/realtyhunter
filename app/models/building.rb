class Building < ApplicationRecord
	audited except: [:created_at, :updated_at, :knack_id]
  scope :unarchived, ->{where(archived: false)}

  before_save :process_rental_term
  before_save :process_custom_amenities
  before_save :process_custom_utilities

	belongs_to :company #, touch: true
	belongs_to :landlord #, touch: true
	belongs_to :neighborhood #, touch: true
	belongs_to :pet_policy # , touch: true
	belongs_to :rental_term #, touch: true
	has_many :units, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

	has_many :images, dependent: :destroy
  has_many :documents, dependent: :destroy

	has_and_belongs_to_many :building_amenities
  has_and_belongs_to_many :trains
	has_and_belongs_to_many :utilities

	attr_accessor :building, :inaccuracy_description, :custom_rental_term, :custom_amenities,
    :custom_utilities, :custom_neighborhood_id, :route_short

  # can't be unique. we might have archived copies with the same address
	validates :formatted_street_address, presence: true, length: {maximum: 200}
		#uniqueness: { case_sensitive: false }

	validates :street_number, allow_blank: true, length: {maximum: 20}
	validates :route, presence: true, length: {maximum: 100}
	# borough
	#:sublocality can be blank
	# city
  validates :dotsignal_code, length: {maximum: 5}
	validates :administrative_area_level_2_short, allow_blank: true, length: {maximum: 100}
	# state
	validates :administrative_area_level_1_short, presence: true, length: {maximum: 100}
	validates :postal_code, allow_blank: true, length: {maximum: 15}
	validates :country_short, presence: true, length: {maximum: 100}
	validates :lat, presence: true, length: {maximum: 100}
	validates :lng, presence: true, length: {maximum: 100}
	validates :place_id, presence: true#, length: {maximum: 100}

  validates :llc_name, allow_blank: true, length: {maximum: 200}

	validates :company, presence: true
  # don't validate landlord presence here - if this building has sales listings instead of rentals,
  # for example, then there will be a seller instead of a landlord. only rentals have landlord info.
  after_commit :trim_audit_log
  def archive
    self.archived = true
    self.save
  end

  def self.find_unarchived(id)
    find_by!(id: id, archived: false)
  end

	def street_address
		if street_number
			street_number + ' ' + route
		else
			route
		end
	end

	def active_units
    units.unarchived.available_on_market.order('updated_at DESC')
	end

	def update_total_unit_count
    self.update_column(:total_unit_count, units.unarchived.count)
	end

	def update_active_unit_count
    active_count = units.unarchived.where('status = ?', Unit.statuses['active']).count
    self.update_column(:active_unit_count, active_count)
	end

  # get first image as thumbnail
  def self.get_bldg_images_from_units(list)
    imgs = Image.where(building_id: list.pluck(:building_id), priority: 0)
    Hash[imgs.map {|img| [img.building_id, img.file.url(:thumb)]}]
  end

  # get first image as thumbnail
  def self.get_images(list)
    imgs = Image.where(building_id: list.ids, priority: 0)
    Hash[imgs.map {|img| [img.building_id, img.file.url(:thumb)]}]
  end

  # returns all images for each building
  def self.get_all_bldg_images(list)
    building_ids = list.map(&:building_id)
    Image.where(building_id: building_ids).to_a.group_by(&:building_id)
  end

  def self._filter_query(running_list, query_str, status, rating, streeteasy_eligibility, filter_dotsignal_code, train_line)
    if query_str
      @terms = query_str.split(" ")
      @terms.each do |term|
        running_list = running_list.where('buildings.formatted_street_address ILIKE ? OR buildings.sublocality ILIKE ?', "%#{term}%", "%#{term}%")
      end
    end

    if !train_line.nil?
      if train_line == "0"
        running_list = running_list
      else
        bldg_ids = Building.joins(:trains).where('train_id =?', train_line).pluck(:id)
        running_list = running_list.where("buildings.id IN (?)", bldg_ids)
      end
    end

    if !filter_dotsignal_code.nil?
      running_list = running_list.where("CAST(buildings.dotsignal_code AS TEXT) ILIKE ?", "%#{filter_dotsignal_code}%")
    end

    if !streeteasy_eligibility.nil?
      if streeteasy_eligibility == "0"
        running_list = running_list.where("buildings.streeteasy_eligibility =?", 0)
      elsif streeteasy_eligibility == "1"
        running_list = running_list.where("buildings.streeteasy_eligibility =?", 1)
      else
        running_list = running_list
      end
    end

    if !rating.nil?
      if rating == "0"
        running_list = running_list.where("buildings.rating =?", 0)
      elsif rating == "1"
        running_list = running_list.where("buildings.rating =?", 1)
      elsif rating == "2"
        running_list = running_list.where("buildings.rating =?", 2)
      elsif rating == "3"
        running_list = running_list.where("buildings.rating =?", 3)
      else
        running_list = running_list
      end
    end

    if !status.nil?
      status_lowercase = status.downcase
      if status_lowercase != 'any'
        if status_lowercase == 'active/pending'
          running_list = running_list.joins(:units)
              .where("units.status IN (?) ",
                [Unit.statuses['active'], Unit.statuses['pending']])
        else
          running_list = running_list.joins(:units)
              .where("units.status = ? ", Unit.statuses[status_lowercase])
        end
      end
    end

    running_list
  end

	def self.search(query_str, status, rating, streeteasy_eligibility, filter_dotsignal_code, train_line)
    running_list = Building
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .where('buildings.archived = false')
      .select(
        'buildings.formatted_street_address', 'buildings.notes', 'buildings.landlord_id', 'buildings.pet_policy_id',
        'buildings.dotsignal_code', 'buildings.streeteasy_eligibility',
        'buildings.id', 'buildings.street_number', 'buildings.route','buildings.rating', 'buildings.streeteasy_eligibility',
        'buildings.sublocality', 'buildings.neighborhood_id', 'neighborhoods.name as neighborhood_name',
        'buildings.administrative_area_level_2_short', 'buildings.dotsignal_code',
        'buildings.administrative_area_level_1_short', 'buildings.postal_code',
        'buildings.updated_at', 'buildings.created_at',
        'buildings.last_unit_updated_at',
        'buildings.total_unit_count',
        'buildings.active_unit_count')

    running_list = Building._filter_query(running_list, query_str, status, rating, streeteasy_eligibility, filter_dotsignal_code, train_line)
    running_list
	end

  # adds in landlord
  def self.export_all(query_str, status, rating, streeteasy_eligibility, filter_dotsignal_code, train_line)
    running_list = Building.joins(:landlord).joins(:rental_term)
      .joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
      .where('buildings.archived = false')
      .select(
        'landlords.code AS landlord_code','landlords.id AS landlord_id',
        'buildings.formatted_street_address', 'buildings.notes',
        'buildings.id', 'buildings.street_number', 'buildings.route','buildings.rating',
        'buildings.sublocality', 'buildings.neighborhood_id', 'neighborhoods.name as neighborhood_name',
        'buildings.administrative_area_level_2_short',
        'buildings.administrative_area_level_1_short', 'buildings.postal_code', 'buildings.llc_name',
        'buildings.updated_at', 'buildings.created_at',
        'buildings.last_unit_updated_at',
        'buildings.total_unit_count',
        'buildings.active_unit_count',
        'rental_terms.id as rental_term_id', 'rental_terms.name')

    running_list = Building._filter_query(running_list, query_str, status, rating, streeteasy_eligibility, filter_dotsignal_code, train_line)
    running_list
  end

	def amenities_to_s
		amenities = self.building_amenities.map{|a| a.name.titleize}
		amenities = amenities ? amenities.join(', ') : "None"
    amenities
	end

	def utilities_to_s
		terms = self.utilities.map{|a| a.name.titleize}
		terms = terms ? terms.join(', ') : "None"
    terms
	end

  def find_or_create_neighborhood(neighborhood, borough, city, state)
		@neigh = Neighborhood.where(name: neighborhood).first
    if !@neigh
      @neigh = Neighborhood.create(
        name: neighborhood,
        borough: borough,
        city: city,
        state: state)
    end
    self.neighborhood = @neigh
  end

  def send_inaccuracy_report(reporter, message)
    if reporter && !message.blank?
      Feedback.create!({
        user_id: reporter.id,
        building_id: self.id,
        description: message
      })
      BuildingMailer.inaccuracy_reported(self.id, reporter.id, message).deliver!
    else
      raise "Invalid params specified while sending feedback"
    end
  end

  def send_creation_notification
    BuildingMailer.send_creation_notification(self.id).deliver
  end

  def residential_units(status=nil)
    ResidentialListing.for_buildings([id], status)
  end

  def commercial_units(status=nil)
    CommercialListing.for_buildings([id], status)
  end

  # used in API, syndication
  def self.get_pet_policies(list)
    bldg_ids = list.pluck(:building_id)
    Building.joins(:pet_policy).where(id: bldg_ids)
      .select('buildings.id', 'pet_policies.name as pet_policy_name')
      .to_a.group_by(&:id)
  end

  def self.get_rental_terms(list_of_units)
    bldg_ids = list_of_units.pluck(:building_id)
    Building.joins(:rental_term).where(id: bldg_ids)
      .select('buildings.id', 'rental_terms.name as rental_term_name')
      .to_a.group_by(&:id)
  end

  # Used in our API
  def self.get_amenities(list_of_units)
    building_ids = list_of_units.map(&:building_id)
    Building.joins(:building_amenities)
        .where(id: building_ids).select('name', 'id')
        .to_a.group_by(&:id)
  end

  # used by building csv
  def self.get_amenities_from_buildings(list_of_bldgs)
    building_ids = list_of_bldgs.pluck(:id)
    Building.joins(:building_amenities)
        .where(id: building_ids).select('name', 'id')
        .to_a.group_by(&:id)
  end

  # Used by syndication
  def self.get_utilities(list_of_units)
    bldg_ids = list_of_units.pluck(:building_id)
    Building.joins(:utilities).where(id: bldg_ids)
        .select('buildings.id', 'utilities.name as utility_name')
        .to_a.group_by(&:id)
  end

  # used by building csv
  def self.get_utilities_from_buildings(list_of_bldgs)
    bldg_ids = list_of_bldgs.pluck(:id)
    Building.joins(:utilities).where(id: bldg_ids)
        .select('buildings.id', 'utilities.name as utility_name')
        .to_a.group_by(&:id)
  end

  # computes the distance between 2 buildings using haversine formula
  # loc2 = [lat, lng]
  def distanceTo loc2
    loc1 = [self.lat.to_f, self.lng.to_f]
    loc2 = [loc2[0].to_f, loc2[1].to_f]

    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    rm * c * 3 # Delta in feet
  end

  # Computes the distance between 2 buildings using pythagoras theorem. It's less accurate but
  # more performant.
  # def distanceTo loc2
  #   loc1 = [self.lat.to_f, self.lng.to_f]
  #   loc2 = [loc2[0].to_f, loc2[1].to_f]
  #   Math.sqrt( (loc2[0]-loc1[0])**2 + (loc2[1]-loc1[1])**2 )
  # end

  private

  	def process_rental_term
  		if custom_rental_term && !custom_rental_term.empty?
  			req = RentalTerm.where(name: custom_rental_term, company: company).first
  			if !req
  				req = RentalTerm.create!(name: custom_rental_term, company: company)
  			end
  			self.rental_term = req
  		end
  	end

    def process_custom_amenities
      if custom_amenities
        amenities = custom_amenities.split(',')
        amenities.each{|a|
          if !a.empty?
            a = a.downcase.strip
            found = BuildingAmenity.where(name: a, company: company).first
            if !found
              self.building_amenities << BuildingAmenity.create!(name: a, company: company)
            end
          end
        }
      end
    end

    def process_custom_utilities
      if custom_utilities
        terms = custom_utilities.split(',')
        terms.each{|t|
          t = t.downcase.strip
          if !t.empty?
            found = Utility.where(name: t, company: company).first
            if !found
              self.utilities << Utility.create!(name: t, company: company)
            end
          end
        }
      end
    end

    def trim_audit_log
      # to keep updates speedy, we cap the audit log at 100 entries per record
      audits_count = audits.length
      if audits_count > 50
        audits.first.destroy
      end

      # we also discard the initial audit record, which is triggered upon creation
      if audits_count > 0 && audits.first.created_at.to_time.to_i == self.created_at.to_time.to_i
        audits.first.update(comment: 'created')
      end
    end

end
