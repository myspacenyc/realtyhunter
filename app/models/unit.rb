class Unit < ApplicationRecord
  audited except: [:created_at, :updated_at], on: [:update]

	belongs_to :building #, touch: true
  belongs_to :primary_agent, class_name: 'User' #, touch: true
  belongs_to :primary_agent2, class_name: 'User' #, touch: true
  has_many :images, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_one :residential_listing, dependent: :destroy
  has_one :commercial_listing, dependent: :destroy
  has_one :sales_listing, dependent: :destroy
  has_many :announcements
  has_many :deals
  has_many :feedbacks, dependent: :destroy
  has_many :open_houses, dependent: :destroy
  has_many :checkins, dependent: :destroy
  accepts_nested_attributes_for :open_houses, allow_destroy: true

  before_validation :generate_unique_id
  after_commit :trim_audit_log

  scope :unarchived, ->{ where(archived: false) }
  scope :active, ->{ where(status: Unit.statuses["active"]) }
  scope :available_on_market, ->{ where("status = ? OR status = ?", Unit.statuses["active"], Unit.statuses["pending"]) }

	enum status: [
    :active, :pending, :off, :rsonly, :rented, #residential
    :offer_submitted, :offer_accepted, :binder_signed, :off_market_for_lease_execution, #additional for commercial
    :on_market, :contract_out, :in_escrow, :closed_off, :closed, :deal_pending # additional for sales
   ]
  validates :status, presence: true, inclusion: {
    in: ['active', 'pending', 'off', 'rsonly', 'rented',
         'offer_submitted', 'offer_accepted', 'binder_signed', 'off_market_for_lease_execution',
         'on_market', 'contract_out', 'in_escrow', 'closed_off', 'closed', 'deal_pending'] }

  enum syndication_status: ['Syndicate if matches criteria', 'Force syndicate', 'Never syndicate']
  validates :syndication_status, presence: true, inclusion: {
    in: ['Syndicate if matches criteria', 'Force syndicate', 'Never syndicate']
  }

  # this should really been called "price", as its used across both rentals and sales
	validates :rent, presence: true, numericality: { only_integer: true }

	validates :listing_id, presence: true, uniqueness: true

  # sales/commercial might not have one yet
  #validates :public_url, presence: true, uniqueness: true

  validates :building_id, presence: true
  validates :building_unit, allow_blank: true, length: {maximum: 50}

  def archive
    self.archived = true
    self.save
  end

  def self.find_unarchived(id)
    find_by!(id: id, archived: false)
  end

  # returns all images for each unit
  def self.get_all_images(list)
    unit_ids = list.pluck('units.id')
    Image.where(unit_id: unit_ids).to_a.group_by(&:unit_id)
  end

  def self.get_open_houses(list)
    unit_ids = list.pluck('units.id')
    OpenHouse.where(unit_id: unit_ids).to_a.group_by(&:unit_id)
  end

  def self.get_agents_by_id(ids)
    primary_agents = User.where(id: ids)
    Hash[primary_agents.map {|agent| [agent.id, agent.name]}]
  end

  def self.get_primary_agents(list)
    User.joins(:office)
      .joins('inner join units on users.id = units.primary_agent_id OR users.id = units.primary_agent2_id')
      .where('units.id IN (?)', list.pluck('units.id'))
      .select('users.id', 'name', 'email', 'mobile_phone_number', 'phone_number', 'public_url',
        'offices.telephone AS office_telephone', 'offices.fax AS office_fax', 'units.id as unit_id')
      .to_a.group_by(&:unit_id)
  end

  # Used by syndication
  def self.get_primary_agents_and_images(list)
    users = User
      .joins(:office)
      .joins('inner join units on users.id = units.primary_agent_id OR users.id = units.primary_agent2_id')
      .where('units.id IN (?)', list.pluck("units.id"))
      .select('users.id', 'name', 'email', 'streeteasy_email', 'mobile_phone_number', 'streeteasy_mobile_number', 'phone_number', 'public_url',
        'offices.telephone AS office_telephone', 'offices.fax AS office_fax', 'units.id as unit_id')

    images = Image.where(user_id: users.ids).index_by(&:user_id)
    return [users.to_a.group_by(&:unit_id), images]
  end

  # mainly for use in our API. Returns list of any
  # agent contacts for this listing. Currently we have
  # 1 primary agent for each listing, but could change in the future.
  def contacts
    # TODO: commercial has 2
    contacts = [primary_agent];
  end

  def mark_app_submitted(user, category, status)
    self.update(status: Unit.statuses[status])
    announcement = Announcement.create({
      category: Announcement.categories['residential'],
      note: 'Application submitted on ' + self.building.street_address,
      user_id: user.id
      })
    announcement.broadcast(user)
  end

  # Used by syndication
  def self.get_open_houses(list_of_units)
    unit_ids = list_of_units.pluck('units.id')
    Unit.joins(:open_houses).where(id: unit_ids)
        .where('open_houses.day >= ?', 1.day.ago)
        .select('units.id', 'open_houses.start_time', 'open_houses.end_time', 'open_houses.day', 'open_houses.appt_only')
        .to_a.group_by(&:id)
  end

  # todo: should really be called notify_new_agent
  def self.update_primary_agent(new_agent_id, old_agent_id, listing_id)
    if !new_agent_id.blank?
      UserMailer.send_primary_agent_added_notification(new_agent_id, listing_id).deliver
    end
  end

  private
    # TODO: code review - should only be set if none exists
    def generate_unique_id
      if !listing_id
        #puts "*** calling generate"
        #if !self.unit.listing_id
          listing_id = SecureRandom.random_number(9999999)
          while Unit.where(listing_id: listing_id).first do
            listing_id = SecureRandom.random_number(9999999)
          end

          self.listing_id = listing_id
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
        audits.first.destroy
      end

    end

end
