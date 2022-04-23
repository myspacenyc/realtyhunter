class Company < ApplicationRecord
	include Bootsy::Container
	default_scope { order("name ASC") }
	scope :unarchived, ->{where(archived: false)}

	has_one :image, dependent: :destroy
	after_create :create_environment
	has_many :offices, :dependent => :destroy
	has_many :users, dependent: :destroy
	accepts_nested_attributes_for :users
	has_many :buildings, dependent: :destroy
	has_many :landlords, dependent: :destroy
	has_many :building_amenities, dependent: :destroy
	has_many :trains, dependent: :destroy
	has_many :utilities, dependent: :destroy
	has_many :rental_terms, dependent: :destroy
	has_many :pet_policies, dependent: :destroy
	has_many :residential_amenities, dependent: :destroy
	has_many :specialties, dependent: :destroy
	has_many :sales_amenities, dependent: :destroy
	has_many :commercial_property_types
	# the following are from wufoo
	has_many :roommates, dependent: :destroy

	#attr_accessor :agent_types, :employee_titles
	#attr_access :building_amenities

	validates :name, presence: true, length: {maximum: 100},
		uniqueness: { case_sensitive: false }

	validates :name, presence: true, length: {maximum: 50},
		uniqueness: { case_sensitive: false }

	validates :privacy_policy, allow_blank: true, length: {maximum: 2000}
	validates :terms_conditions, allow_blank: true, length: {maximum: 2000}

  def archive
    self.archived = true
    self.save
  end

  def self.find_unarchived(id)
    find_by!(id: id, archived: false)
  end

	# should we limit this to 1 per company?
	def admins
		self.users.unarchived
			.joins(:roles)
			.where('roles.name = ?', 'company_admin')
			.includes(:employee_title, :office, :image, :manager)
	end

	def managers
		 self.users.unarchived
			.joins(:roles, :office, :employee_title)
			.where('roles.name = ?', 'manager')
			.includes( :manager, )
			.select('users.company_id', 'users.archived', 'users.id',
        'users.name', 'users.email', 'users.activated', 'users.approved', 'users.last_login_at',
        'users.mobile_phone_number',
        'employee_titles.id AS employee_title_id',
        'employee_titles.name AS employee_title_name',
        'offices.name AS office_name', 'offices.id as office_id',
        'users.manager_id')
	end

	def agents
		self.users.unarchived
			.joins(:office, :employee_title)
			.order(:name)
			.select('users.company_id', 'users.archived', 'users.id',
        'users.name', 'users.email', 'users.activated', 'users.approved', 'users.last_login_at',
        'users.mobile_phone_number',
        'employee_titles.id AS employee_title_id',
        'employee_titles.name AS employee_title_name',
        'offices.name AS office_name', 'offices.id as office_id',
        'users.manager_id')
	end

	def employees
		self.users.unarchived
      .joins(:office, :employee_title)
      .includes(:manager, :roles)
      .select('users.company_id', 'users.archived', 'users.id',
        'users.name', 'users.email', 'users.activated', 'users.approved', 'users.last_login_at',
        'employee_titles.name AS employee_title_name', 'employee_titles.id AS employee_title_id',
        'offices.name AS office_name', 'offices.id as office_id',
        'users.manager_id')
	end

  def employees_for_export
    self.users.unarchived
      .joins(:office, :employee_title)
      .includes(:manager, :roles)
      .select('users.company_id', 'users.archived', 'users.id', 'users.phone_number',
        'users.mobile_phone_number', 'users.last_login_at', 'users.bio',
        'users.name', 'users.email', 'users.activated', 'users.approved',
        'employee_titles.name AS employee_title_name', 'employee_titles.id AS employee_title_id',
        'offices.name AS office_name', 'offices.id as office_id',
        'users.manager_id', 'users.created_at', 'users.updated_at', 'users.archived')
  end

	def update_employee_titles
		employee_titles.split(/\r?\n/).each {|e|
      sanitized_name = EmployeeTitle.sanitize_name(e)
      EmployeeTitle.find_or_create_by(name: sanitized_name)
    }
	end

	def self.search(query_params)
    running_list = Company.unarchived
    if !query_params || !query_params[:name]
      return running_list
    end

    query_string = query_params[:name]
    query_string = query_string[0..500] # truncate for security reasons
    terms = query_string.split(" ")
    terms.each do |term|
      running_list = running_list.where('name ILIKE ?', "%#{term}%").all
    end

    running_list.distinct
  end

	# Create the default environment options for the company.
	# Admins can always change them once the company has been created.
	def create_environment
		BuildingAmenity.create!([
			{name: "Fitness Center", company: self},
			{name: "Sauna", company: self},
			{name: "Doorman", company: self},
			{name: "Laundry in Bldg", company: self},
			{name: "Bike Room", company: self},
			{name: "Brownstone", company: self},
			{name: "Storage", company: self},
			{name: "Roof Deck", company: self},
			{name: "Garage Parking", company: self},
			{name: "Parking", company: self},
			{name: "Elevator", company: self}
		])

		Utility.create!([
			{name: "Heat included", company: self},
			{name: "Hot water included", company: self},
			{name: "Heat/hot water included", company: self},
			{name: "Gas included", company: self},
			{name: "Electric included", company: self},
			{name: "Cable included", company: self},
			{name: "Internet included", company: self},
			{name: "All utils included", company: self},
			{name: "No utils included", company: self},
			{name: "Water not included", company: self},
			{name: "Trash not included", company: self},
		])

		RentalTerm.create!([
			{name: "First & Security", company: self},
			{name: "First, Last & Security", company: self},
			{name: "First & 2 Securities", company: self},
			{name: "First, Security & Broker's Fee", company: self},
		])

		PetPolicy.create!([
			{name: "Cats only", company: self},
			{name: "Dogs only", company: self},
			{name: "Pets ok", company: self},
			{name: "Small pets ok (<30 lbs)", company: self},
			{name: "Pets upon approval", company: self},
			{name: "Monthly pet fee", company: self},
			{name: "Pet deposit required", company: self},
			{name: "No pets", company: self},
		])

		ResidentialAmenity.create!([
			{name: "Washer/dryer in unit", company: self},
			{name: "Washer/dryer hookups", company: self},
			{name: "Central A/C", company: self},
			{name: "Central heat", company: self},
			{name: "Airconditioning unit", company: self},
			{name: "Balcony/Terrace", company: self},
			{name: "Hardwood floors", company: self},
			{name: "Private yard", company: self},
			{name: "Shared yard", company: self},
			{name: "Bay windows", company: self},
			{name: "Dishwasher", company: self},
			{name: "Microwave", company: self},
			{name: "Duplex", company: self},
			{name: "Triplex", company: self},
			{name: "Railroad", company: self},
			{name: "Renovated", company: self},
			{name: "Roof access", company: self},
			{name: "Skylight", company: self},
			{name: "Walk-in closet", company: self},
			{name: "Waterfront", company: self},
		])

		CommercialPropertyType.create!([
			{property_type: "Retail", property_sub_type: "Retail - Retail Pad", company: self},
			{property_type: "Retail", property_sub_type: "Retail - Free Standing Bldg", company: self},
			{property_type: "Retail", property_sub_type: "Retail - Street Retail", company: self},
			{property_type: "Retail", property_sub_type: "Retail - Vehicle Related", company: self},
			{property_type: "Retail", property_sub_type: "Retail - Retail (Other)", company: self},
			{property_type: "Office", property_sub_type: "Office - Office (Other)", company: self},
			{property_type: "Industrial", property_sub_type: "Industrial - Industrial (Other)", company: self},
			{property_type: "Land", property_sub_type: "Land - Land (Other)", company: self},
			{property_type: "Special Purpose", property_sub_type: "Special Purpose - Special Purpose (Other)", company: self},
			{property_type: "Medical", property_sub_type: "Medical - Misc", company: self},
		])
	end
end
