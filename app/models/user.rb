class User < ApplicationRecord
  # audited except: [:created_at, :updated_at]
  rolify
  default_scope { order("users.name ASC") }
  scope :unarchived, ->{where(archived: false)}

  # has_and_belongs_to_many :roles, :join_table => :users_roles
  belongs_to :office, touch: true
  belongs_to :company, touch: true
  belongs_to :manager, :class_name => "User"
  belongs_to :employee_title
  has_and_belongs_to_many :specialties
  has_many   :subordinates, :class_name => "User", :foreign_key => "manager_id"
  # A unit can have up to 2 assigned or "primary" agents
  # if you are assigned agent #1
  has_many :primary_units, class_name: 'Unit', :foreign_key => 'primary_agent_id'
  # if you are assigned agent #2
  has_many :primary2_units, class_name: 'Unit', :foreign_key => 'primary_agent2_id'
  # A unit can have only 1 listing agent
  has_many :listed_units,  class_name: 'Unit', :foreign_key => 'listing_agent_id'
  has_many :roommates#, class_name: 'WufooRoommatesWebForm'
  has_many :roomsharing_applications
  has_many :user_waterfalls, class_name: 'UserWatefall', foreign_key: 'parent_agent_id'
  has_one :image, dependent: :destroy
  has_many :announcements
  has_many :deals
  has_many :checkins, dependent: :destroy
  has_many :feedbacks
  has_many :user_login_details, dependent: :destroy

	before_create :create_activation_digest
  before_create :set_auth_token # for API
  before_save :sanitize_email

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
	validates :email, presence: true, length: {maximum: 100},
						format: { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: false }

  validates :streeteasy_email, presence: true, length: {maximum: 100},
            format: { with: VALID_EMAIL_REGEX }

  VALID_TELEPHONE_REGEX = /\A(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?\z/
  validates :mobile_phone_number, length: {maximum: 25}, allow_blank: true, #presence: true,
    format: { with: VALID_TELEPHONE_REGEX }

  validates :streeteasy_mobile_number, length: {maximum: 25}, allow_blank: true, #presence: true,
    format: { with: VALID_TELEPHONE_REGEX }

  validates :name, presence: true, length: {maximum: 50}
  has_secure_password
	validates :password, length: { minimum: 6 }, allow_blank: true
  validates :bio, length: {maximum: 2000}
  validates :company, presence: true
  validates :office, presence: true

  attr_accessor :remember_token, :activation_token, :reset_token, :approval_token, :agent_types, :batch

  def has_role?(role_name)
    self.roles.any? {|r| r.name == role_name.to_s}
  end

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def _get_listings_by_status(listings, status)
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
    listings
  end

  # primary units only currently
  def residential_units(status=nil)
    ids = self._get_listings_by_status(self.primary_units, status).ids +
        self._get_listings_by_status(self.primary2_units, status).ids
    ResidentialListing.for_units(ids)
  end

  # primary units only currently
  def commercial_units(status=nil)
    ids = self._get_listings_by_status(self.primary_units, status).ids +
        self._get_listings_by_status(self.primary2_units, status).ids
    CommercialListing.for_units(ids)
  end

  # Returns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token = User.new_token
    update_columns(remember_digest: User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def forget
    self.update(remember_digest: nil)
  end

  # Activates an account.
  def activate
    self.update(activated: true, activated_at: Time.zone.now)
  end

  # Marks an account as approved by an admin
  def approve
    self.update(approved: true, approved_at: Time.zone.now)
  end

  def unapprove
    self.update(approved: false, approved_at: nil)
  end

  def archive
    self.update(archived: true)
  end

  def self.find_unarchived(id)
    self.find_by!(id: id, archived: false)
  end

  def fname
    self.name.split(' ')[0]
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self.id).deliver!
  end

  # sends the company admin a notification, asking to
  # approve this user
  def send_company_approval_email
    UserMailer.account_approval_needed(self.id, self.company.id).deliver!
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token),
                   reset_sent_at: Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    create_reset_digest
    @user = User
        .where(id: id)
        .where(archived: false)
        .where(activated: true)
        .first
    if @user
      UserMailer.password_reset(id, reset_token).deliver!
    end
  end

  def assign_random_password
    # self.password = '123456'
    self.password = SecureRandom.base64
  end

  # Sends password reset email.
  def send_added_by_admin_email(company)
    create_reset_digest
    UserMailer.added_by_admin(company.id, id, reset_token).deliver!
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def self.get_images(list)
    imgs = Image.where(user_id: list.ids)
    Hash[imgs.map {|img| [img.user_id, img.file.url(:thumb)]}]
  end

  def self.search(query_params, current_user)
    running_list = User
      .joins(:office, :employee_title)
      .where(company: current_user.company)
      .select('users.company_id', 'users.archived', 'users.id',
        'users.name', 'users.email', 'users.activated', 'users.approved', 'users.last_login_at',
        'employee_titles.name AS employee_title_name', 'employee_titles.id AS employee_title_id',
        'offices.name AS office_name', 'offices.id as office_id', 'users.manager_id')

    if !query_params
      return running_list
    end

    if !query_params[:name_email].blank?
      query_string = query_params[:name_email]
      terms = query_string.split(" ")
      terms.each do |term|
        running_list = running_list.where('users.name ILIKE ? or users.email ILIKE ?', "%#{term}%", "%#{term}%").all
      end
    end

    if !query_params[:status].blank?
      if query_params[:status].downcase == 'active'
        running_list = running_list.where("users.archived = false")
      elsif query_params[:status].downcase == 'deleted'
        running_list = running_list.where("users.archived = true")
      end
    end

    running_list
  end


  # assign sensible defaults for user accounts
  def update_roles
    # clear out old roles
    #self.roles = [];

    # add a role representing your position in the company.
    # default to an agent if none otherwise specified
    if !self.employee_title
      self.employee_title = EmployeeTitle.agent
      self.save
    end

    # right now, agents should have access to all the basic listing types
    self.add_role :agent unless self.roles.any?
  end

  # def handles_residential?
  #   self.has_role? :residential
  # end

  # def handles_commercial?
  #   self.has_role? :commercial
  # end

  # def handles_sales?
  #   self.has_role? :sales
  # end
  def is_super_admin?
    self.has_role? :super_admin
  end

  def is_company_admin?
    self.has_role? :company_admin
  end

  def is_external_vendor?
    self.has_role? :external_vendor
  end

  def is_agent?
    employee_title == EmployeeTitle.agent
  end

  def is_special_agent?
    self.has_role? :agent
  end

  # does this user actually manage other agents?
  def is_manager?
    self.has_role? :manager
  end

  def is_photo_manager?
    self.has_role? :photo_manager
  end

  def is_hired_photographer?
    self.has_role? :hired_photographer
  end

  def is_third_tier_agent?
    self.has_role? :third_tier_agent
  end

  def is_s_agents?
    self.has_role? :s_agents
  end

  def is_listings_manager?
    has_role? :listings_manager
  end

  def is_streeteasy_agent?
    has_role? :streeteasy_agent
  end

  def is_data_entry?
    self.has_role? :data_entry
  end

  def is_data_entry2?
    self.has_role? :data_entry2
  end

  # Many roles can be considered 'managerial' from
  # a staffing point of view. Any employees that work
  # in operations should have permission to edit
  # listings or users. This is a catch-all function.
  def is_management?
    # self.roles.any? {|r| r.name == role_name.to_s}
    management_roles = [
      :super_admin,
      :company_admin,
      :operations,
      :manager,
      :data_entry,
      :data_entry2]
    management_roles.each do |r|
      return true if self.has_role? r
    end

    false
  end

  def self.valid_roles_list(logged_in_user)
    management_roles = [
      :super_admin,
      :company_admin,
      :operations,
      :manager,
      :data_entry,
      :data_entry2]

    logged_in_user_is_management = false
    management_roles.each do |r|
      if logged_in_user.has_role? r
        logged_in_user_is_management = true
        break
      end
    end

    if logged_in_user.has_role?(:super_admin)
      Role.all
    elsif logged_in_user_is_management
      Role.where.not(name: 'super_admin')
    else
      Role.where('name NOT IN (?)', management_roles)
    end
  end

  def make_manager
    self.employee_title = EmployeeTitle.manager
    self.add_role :manager
    self.update_roles
  end

  def make_company_admin
    self.employee_title = EmployeeTitle.company_admin
    self.add_role :company_admin
    self.update_roles
  end

  def add_subordinate(subord)
    if self.has_role? :manager
      subord.manager = self
      subord.save
      #puts "#{subord.manager.name} "
      #puts "#{subord.manager.subordinates.length} \n\n"
    else
      raise 'Tried to add subordinate without being manager first'
    end
  end

  def remove_subordinate(subord)
    if self.has_role? :manager
      subord.manager = nil
    else
      raise 'Tried to remove subordinate without being manager first'
    end
  end

  def coworkers
    company.users.preload(:roles)
  end

  # In order to approve another user, we must be:
  # - A company admin
  # - From the same company as the other user
  # - Higher in rank than the other user
  def can_approve(other_user)
    if other_user.employee_title_id && self.employee_title_id
      return self.is_company_admin? &&
    other_user.employee_title_id < self.employee_title_id
    else
      return self.is_company_admin? &&
    other_user.employee_title.id < self.employee_title.id
    end
  end

  # In order to kick another user from their team, we must be:
  # - at the same company
  # - either their direct manager or a company admin
  def can_kick(other_user)
    return other_user.manager &&
    (self.is_company_admin? ||
    (self == other_user.manager))
  end

  def kick
    self.manager = nil
    self.save
  end

  # In order to manage a team:
  # - The other user must be a manager
  # - We need to be a company admin or the manager in question
  # - We must both work for the same company
  def can_manage_team(other_user)
    return other_user.is_manager? &&
    (self.is_company_admin? || self == other_user)
  end

  # for use in our API
  def set_auth_token
    return if auth_token.present?
    self.auth_token = generate_auth_token
  end

  private

    def sanitize_email
      self.email = email.downcase
      email_md5 = Digest::MD5.hexdigest(self.email)
      self.public_url = "http://myspacenyc.com/agent/AGENT-#{email_md5}"
    end

    def create_activation_digest
      # Create the token and digest.
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
      self.approval_token  = User.new_token
      self.approval_digest = User.digest(approval_token)
    end

    # for use in our API
    def generate_auth_token
      loop do
        token = SecureRandom.hex
        found_user = User.where(auth_token: token).first
        #break token unless found_user #self.class.exists?(auth_token: token)
        if !found_user
          return token
        end

      end
      #puts "done"
    end

end
