  class SyndicationController < ApplicationController
  skip_authorize_resource
  skip_before_action :logged_in_user
  protect_from_forgery with: :null_session
  include SyndicationInterface

  def naked_apts
    set_listings
  end

  def streeteasy
    set_listings
  end

  def apartment
    set_listings
  end

  def trulia
    set_listings
  end

  def zillow
    set_listings
  end

  def nestio
    set_listings
  end

  def dotsignal
    set_listings
  end

  def hotpad
    set_listings
  end

  def rooms
    set_listings
  end

  def zumper
    set_listings
  end

  def renthop
    set_listings
  end

  def rhexport
    set_listings
  end

  def external_feed
    set_listings
  end

  def test_watermark
    set_listings
  end

  def zumper_backup
    set_listings
  end

  def external_feed_no_rooms
    set_listings
  end

  def all_active_users
    @users = User.where(archived: false)
    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  def set_listings
    @company = Company.find(syndication_params[:id])
    if @company
      if syndication_params[:action] == 'naked_apts'
        @listings = naked_apts_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'streeteasy'
        @listings = streeteasy_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'trulia'
        @listings = trulia_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'zillow'
        @listings = trulia_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'nestio'
        @listings = nestio_listings(@company.id, {})
      elsif syndication_params[:action] == 'dotsignal'
        @listings = dotsignal_listings(@company.id, {})
      elsif syndication_params[:action] == 'hotpad'
        @listings = hotpad_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'rooms'
        @listings = rooms_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'apartment'
        @listings = apartment_listings(@company.id, {})
      elsif syndication_params[:action] == 'zumper'
        @listings = zumper_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'zumper_backup'
        @listings = zumper_backup_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'external_feed'
        @listings = external_feed_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'external_feed_no_rooms'
        @listings = external_feed_no_rooms_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'test_watermark'
        @listings = test_watermark_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'renthop'
        @listings = renthop_listings(@company.id, syndication_params)
      elsif syndication_params[:action] == 'rhexport'
        @listings = rhexport_listings(@company.id, syndication_params)
      end

      @pet_policies = Building.get_pet_policies(@listings)
      @residential_amenities = ResidentialListing.get_amenities(@listings)
      @building_amenities = Building.get_amenities(@listings)
      @images = Unit.get_all_images(@listings)
      @bldg_images = Building.get_all_bldg_images(@listings)
      @utilities = Building.get_utilities(@listings)
      @open_houses = Unit.get_open_houses(@listings)

      # can you cache a function like this?
      @primary_agents, @agent_images = Unit.get_primary_agents_and_images(@listings)

      respond_to do |format|
        format.rss { render layout: false }
      end
    end
  end

  def syndication_params
    params.permit(:format, :id, :network, :action)
  end
end
