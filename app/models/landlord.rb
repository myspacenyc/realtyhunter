class Landlord < ApplicationRecord
  audited except: [:created_at, :updated_at, :active_unit_count, :total_unit_count, :knack_id]

	scope :unarchived, ->{where(archived: false)}

	has_many :buildings, dependent: :destroy
  has_many :landlord_contacts, dependent: :destroy
	belongs_to :company #, touch: true
	validates :company_id, presence: true

  belongs_to :listing_agent, :class_name => 'User' #, touch: true
  belongs_to :point_of_contact, class_name: 'User'
  # validates :listing_agent_percentage, presence: true, length: {maximum: 3}, numericality: { only_integer: true }
  validates :listing_agent_id, presence: true
  validates :point_of_contact_id, presence: true
  # validates :percentage_invoiced_to_ll, presence: true
  # validates :op_fee_percentage, presence: true
  # validates :back_to_owner, presence: true
  # validates :myspacenyc_percentage, presence: true
	validates :code, presence: true, length: {maximum: 100},
		uniqueness: { case_sensitive: false }

	validates :name, presence: true, length: {maximum: 100}

	VALID_TELEPHONE_REGEX = /\A(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?\z/
	validates :mobile, allow_blank: true, length: {maximum: 25},
		format: { with: VALID_TELEPHONE_REGEX }
	# validates :office_phone, allow_blank: true, length: {maximum: 25},
	# 	format: { with: VALID_TELEPHONE_REGEX }
	validates :fax, allow_blank: true, length: {maximum: 25},
		format: { with: VALID_TELEPHONE_REGEX }

	before_save :clean_up_important_fields
  after_commit :trim_audit_log

	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
	validates :email, allow_blank: true, length: {maximum: 100},
		format: { with: VALID_EMAIL_REGEX },
    uniqueness: { case_sensitive: false }

  def archive
    self.update({archived: true})
  end

  def self.find_unarchived(id)
    find_by!(id: id, archived: false)
  end

	def update_active_unit_count
		self.update_columns(active_unit_count:
        buildings.unarchived.reduce(0){|sum, bldg| sum + bldg.active_units.count })
	end

	def update_total_unit_count
		self.update_columns(total_unit_count:
        buildings.unarchived.reduce(0){|sum, bldg| sum + bldg.units.count })
	end

	def self._search(running_list, params)
		if !params
	    return running_list
  	end

  	if params[:filter]
	    terms = params[:filter].split(" ")
	    terms.each do |term|
	      running_list = running_list.where('landlords.name ILIKE ? or landlords.code ILIKE ?',
            "%#{term}%", "%#{term}%").all
	    end
	  end

    if params[:listing_agent_id]
      running_list = running_list.where("listing_agent_id IN (?)", params[:listing_agent_id])
    end

    rating = params[:rating]
    if !rating.nil?
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

    ll_importance = params[:ll_importance]
    if !ll_importance.nil?
      if ll_importance == "gold"
        running_list = running_list.where("landlords.ll_importance =?", 'gold')
      elsif ll_importance == "silver"
        running_list = running_list.where("landlords.ll_importance =?", 'silver')
      elsif ll_importance == "bronze"
        running_list = running_list.where("landlords.ll_importance =?", 'bronze')
      else
        running_list = running_list
      end
          
        
    end

    status = params[:status]
    if !status.nil?
      status_lowercase = status.downcase
      if status_lowercase != 'any'
        if status_lowercase == 'active/pending'
          running_list = running_list.joins(buildings: :units)
              .where("units.status IN (?) ",
                [Unit.statuses['active'], Unit.statuses['pending']])
        else
          running_list = running_list.joins(buildings: :units)
              .where("units.status = ? ", Unit.statuses[status_lowercase])
        end
      end
    end

    running_list.distinct
	end

	def self.search_csv(params, user)
		running_list = Landlord.unarchived.joins(:company)
      .joins('left join users on users.id = landlords.listing_agent_id')
      .includes(:buildings)
      .where('companies.id = ?', user.company_id)
      .select('landlords.*', 'users.name as listing_agent_name')
		self._search(running_list, params)
	end

	def self.search(params, user)
		running_list = Landlord.unarchived.joins(:company)
      .joins('left join users on users.id = landlords.listing_agent_id')
      .where('companies.id = ?', user.company_id)

    running_list = self._search(running_list, params)
		running_list = running_list.select('landlords.id', 'landlords.code', 'landlords.name',
				'landlords.updated_at', 'landlords.mobile', 'landlords.rating', 'landlords.ll_importance',
				'landlords.active_unit_count', 'landlords.total_unit_count',
				'landlords.last_unit_updated_at', 'landlords.listing_agent_id',
        'users.name as listing_agent_name', 'landlords.listing_agent_percentage')
	end

	def residential_units(status=nil)
    bldg_ids = self.building_ids
    ResidentialListing.for_buildings(bldg_ids, status)
  end

  def commercial_units(status=nil)
  	bldg_ids = self.building_ids
    CommercialListing.for_buildings(bldg_ids, status)
  end

  def send_creation_notification
    LandlordMailer.send_creation_notification(self.id).deliver
  end

	private
    def clean_up_important_fields
    	if email
      	self.email = email.gsub(/\A\p{Space}*|\p{Space}*\z/, '').downcase
     	end

			self.name = name.gsub(/\A\p{Space}*|\p{Space}*\z/, '')
			self.code = code.gsub(/\A\p{Space}*|\p{Space}*\z/, '')
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
