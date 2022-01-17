class AnnouncementsController < ApplicationController
	load_and_authorize_resource
  skip_load_resource only: :create
  #before_action :set_announcement, only: [:index, :new, :create]

  def new
  	@announcement = Announcement.new
  end

	def create
    # NOTE: for now, we've decided to just email myspaceupdates google group.
    # This means 'everyone' will be getting all updates, all the time.
		@announcement = Announcement.new(announcement_params[:announcement])
    if @announcement.save
    	@announcement.broadcast(current_user)
    	flash[:info] = "Announcement sent!"
      redirect_to action: 'new'
    else
      # error
      # puts @announcement.errors.messages
      render 'new'
    end
	end

  def filter
    set_announcements
    respond_to do |format|
      format.js
    end
  end

	def index
    set_announcements
	end

  def delete_modal
    @announcement = Announcement.find(params[:id])
    @params_copy = params
    @params_copy.delete('action')
    @params_copy.delete('controller')
    @params_copy.delete('id')
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @announcement = Announcement.find(params[:id])
    @announcement.destroy

    # for residential page
    @announcement_items = Announcement.search({limit: 4})
    # for announcements page
    set_announcements

    respond_to do |format|
      format.html { redirect_to forms_careers_url, notice: 'Announcement was successfully inactivated.' }
      format.json { head :no_content }
      format.js
    end
  end

	private

    def set_announcements
      @announcements = Announcement.search(announcement_params)
      @announcements = @announcements.page(params[:page])
    end

  	def announcement_params
  		data = params.permit(:id,
        :limit, :res_limit, :com_limit, :sales_limit, :event_limit,
        :created_start, :created_end, :category_filter,
        announcement: [
          :id, :category, :note, :user])

      if data[:announcement]
        if !data[:announcement].blank?
          data[:announcement][:category] = data[:announcement][:category].downcase
        end

        if !data[:announcement][:user]
          data[:announcement][:user] = current_user
        end
      end

      data
    end

end
