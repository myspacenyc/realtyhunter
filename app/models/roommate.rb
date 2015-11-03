#
# Data pulled from Wufoo form or roommate referral form on RealtyHunter.
#
#
class Roommate < ActiveRecord::Base
  belongs_to :user, touch: true
  belongs_to :neighborhood, touch: true
  belongs_to :company, touch: true
	belongs_to :residential_listing

  scope :unarchived, ->{where(archived: false)}

  validates :name, presence: true, length: {maximum: 200}
  validates :phone_number, presence: true, length: {maximum: 20}
  validates :email, presence: true, length: {maximum: 100}
  validates :how_did_you_hear_about_us, length: {maximum: 1000}
  validates :describe_yourself, allow_blank: true, length: {maximum: 1000}
  validates :upload_picture_of_yourself, length: {maximum: 500}
  validates :monthly_budget, length: {maximum: 50}
  validates :move_in_date, length: {maximum: 50}
  validates :dogs_allowed, length: {maximum: 50}
  validates :cats_allowed, length: {maximum: 50}
  validates :internal_notes, length: {maximum: 1000}

  def archive
    self.archived = true
    self.save
  end
  
  def unarchive
    self.archived = false
    self.save
  end

  def self.find_unarchived(id)
    Roommate.where(id: id).where(archived:false).first
  end

  def self.pull_data_for_export(ids)
    roommates = Roommate
      .joins('left join users on roommates.user_id = users.id')
      .joins('left join neighborhoods on roommates.neighborhood_id = neighborhoods.id')
      .where(id: ids)
      .select(
        'roommates.id',
        'roommates.upload_picture_of_yourself',
        'roommates.name', 'roommates.phone_number', 'roommates.email', 
        'roommates.how_did_you_hear_about_us', 'roommates.describe_yourself', 
        'roommates.monthly_budget',
        'roommates.upload_picture_of_yourself', 'roommates.move_in_date',
        'neighborhoods.name as neighborhood_name',
        'roommates.dogs_allowed', 'roommates.cats_allowed', 'roommates.created_by', 
        'roommates.archived', 'users.name as user_name', 'roommates.created_at', 'roommates.updated_at')
  end

  def self.search(params)
    roommates = Roommate
      .joins('left join neighborhoods on roommates.neighborhood_id = neighborhoods.id')
      .select(
    	  'roommates.id', 'roommates.read',
    	  'roommates.upload_picture_of_yourself',
    	  'roommates.name', 'roommates.phone_number', 'roommates.email', 
    	  'neighborhoods.name as neighborhood_name',
    	  'roommates.monthly_budget', 'roommates.move_in_date', 'roommates.dogs_allowed', 
    	  'roommates.cats_allowed', 'roommates.created_at as submitted_date',
    	  'roommates.archived', 'roommates.residential_listing_id')

	   # all search params come in as strings from the url
    # clear out any invalid search params
    params.delete_if{ |k,v| (!v || v == 0 || v.empty?) }

    if !params[:ids].blank?
      roommates = roommates.where(id: params[:ids])
    end

    if !params[:name].blank?
      roommates = roommates.where(name: params[:name])
    end

    if !params[:referred_by].blank?
      if params[:referred_by] == 'Website'
        roommates = roommates.where(user_id: nil)
      else
	    user = User.find_by(name: params[:referred_by])
	    roommates = roommates.where(user_id: user)
      end
    end

    if !params[:neighborhood_id].blank?
      nabe = Neighborhood.find_by(id: params[:neighborhood_id])
      roommates = roommates.where(neighborhood_id: nabe.id)
    end

    if !params[:submitted_date].blank?
      roommates = roommates.where('roommates.created_at >= ?', params[:submitted_date])
    end

    if !params[:move_in_date].blank?
      roommates = roommates.where('roommates.move_in_date >= ?', params[:move_in_date])
    end

    if !params[:monthly_budget].blank?
      roommates = roommates.where('roommates.monthly_budget = ?', params[:monthly_budget])
    end

    if !params[:dogs_allowed].blank?
      roommates = roommates.where('roommates.dogs_allowed = ?', params[:dogs_allowed])
    end

    if !params[:cats_allowed].blank?
      roommates = roommates.where('roommates.cats_allowed = ?', params[:cats_allowed])
    end

    if !params[:status].blank? && params[:status] != 'Any'
      archived = (params[:status] == 'Matched') ? true : false
      roommates = roommates.where('roommates.archived = ?', archived)
    end
    
    roommates
  end

  def self.send_message(source_agent, recipients, sub, msg, roommate_ids)
    if source_agent
      RoommateMailer.send_message(source_agent, recipients, sub, msg, roommate_ids).deliver_now
    else
      "No sender specified"
    end
  end

  def mark_read
    if !read
      self.update_attribute(:read, true)
    end
  end

  def is_matched?
    !self.residential_listing_id.blank?
  end

  # returns true if the roommate can be matched with the target apartment
  # if the apartment already has enough roommates, or was not found
  # then return false
  def match(params)
    if params[:address].blank? || params[:unit_id].blank?
      return false
    end

    listing = ResidentialListing.joins(:unit)
      .where(unit_id: params[:unit_id]).limit(1).first
    
    if listing && listing.roommates.count < listing.beds
      listing.roommates << self
      self.archive
      return true
    else
      return false
    end
  end

  # returns true if the roommates can be matched with the target apartment
  # if the apartment does not have enough space for all the roommates,
  # or was not found then return false
  def self.match(params)
    if params[:address].blank? || params[:unit_id].blank?
      return false
    end

    listing = ResidentialListing.joins(:unit)
      .where(unit_id: params[:unit_id]).limit(1).first
    if !listing
      return false
    end

    new_roommates = Roommate.where(id: params[:ids].split(' '))
    if listing.roommates.count + new_roommates.count <= listing.beds
      listing.roommates << new_roommates
      new_roommates.each{ |r| r.archive }
      return true
    else
      return false
    end
  end

end