class ApartmentMailer < ApplicationMailer
  default from: 'suumomailer@gmail.com'

  def apartment_email
    @apartments = params[:apartments]
    @open_all = 'https://suumo-mailer.netlify.app?'
    @apartments.each {|apartment| @open_all = @open_all + "apartment=#{CGI.escape(apartment[:href])},#{apartment[:address]}&"}
    @url = params[:url]
    to = params[:to]
    if @apartments.size == 0
      puts "0 new apartments - email not sent"
      return
    end
    puts "#{@apartments.size} new apartments sent to #{to}"
    mail(to: to, subject: "New apartments: #{@apartments.size}")
  end
end
