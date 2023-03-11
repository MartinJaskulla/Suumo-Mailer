class ApartmentMailer < ApplicationMailer
  default from: 'suumomailer@gmail.com'

  def apartment_email
    @apartments = params[:apartments]
    @url = params[:url]
    to = params[:to]
    if @apartments.size == 0
      puts "Not sending email to #{to} - #{@apartments.size} new apartments"
      return
    end
    puts "#{@apartments.size} new apartments sent to #{to}"
    mail(to: to, subject: "New apartments: #{@apartments.size}")
  end
end
