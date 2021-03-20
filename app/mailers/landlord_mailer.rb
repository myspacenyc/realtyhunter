class LandlordMailer < ApplicationMailer
  def send_creation_notification(landlord_id)
    @landlord = Landlord.where(id: landlord_id).first
    mail to: ['rakshit@myspacenyc.com'],
      subject: "New landlord created: #{@landlord.code}",
        reply_to: ['rakshit@myspacenyc.com'],
        tag: 'landlord_created',
        track_opens:'true'
  end
end
