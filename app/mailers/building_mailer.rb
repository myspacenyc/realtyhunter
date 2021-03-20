class BuildingMailer < ApplicationMailer
  def inaccuracy_reported(building_id, reporter_id, message)
    @building = Building.where(id: building_id).first
    @reporter = User.where(id: reporter_id).first
    @message = message
    @point_of_contact = User.find(@building.point_of_contact).email
    mail to: ["info@myspacenyc.com", @point_of_contact, "l2t1k3r4a8g8l4s2@msnyc1.slack.com"],
        cc: @reporter.email,
    	subject: "Feedback provided for #{@building.street_address}",
        reply_to: @reporter.email,
        tag: 'building_inaccuracy',
        track_opens:'true'
  end

  def send_creation_notification(building_id)
    @building = Building.where(id: building_id).first
    mail to: ['rakshit@myspacenyc.com'],
      subject: "New building created: #{@building.street_address}",
        reply_to: ['rakshit@myspacenyc.com'],
        tag: 'building_created',
        track_opens:'true'
  end
end
