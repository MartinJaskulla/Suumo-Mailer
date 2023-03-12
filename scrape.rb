# -*- encoding: utf-8 -*-
require 'httpclient'
require 'hpricot'

class HtmlParser
  @@house = '.cassetteitem'
  @@apartment = 'tbody'
  @@href = '.js-cassette_link_href'
  @@rent = '.cassetteitem_price--rent'

  def self.href(apartment)
    # Two apartments of the same house have random jnc_ and bc= values
    # https://suumo.jp/chintai/jnc_000036589660/?bc=100318741343
    return "https://suumo.jp/#{apartment.search(@@href).attr("href")}"
  end

  def self.rent(apartment)
    # 4.6万円 -> 4.6
    return apartment.search(@@rent).inner_text.to_f
  end

  def self.apartments(html)
    result = Array.new
    houses = Hpricot(html).search @@house
    houses.each do |house|
      apartments = house.search(@@apartment)
      highest_rent_apartment = nil
      highest_rent = 0
      apartments.each do |apartment|
        rent = HtmlParser.rent(apartment)
        if rent > highest_rent
          highest_rent_apartment = apartment
          highest_rent = rent
        end
      end
      result.push({ href: HtmlParser.href(highest_rent_apartment) })
    end
    return result
  end
end

class Scraper
  def initialize(mail, url)
    @mail = mail
    @url = url
    @client = HTTPClient.new
  end

  def scrape
    puts @url

    # TODO If query runs for first time, only do not send email
    query = Query.find_or_create_by(url: @url)

    apartments = Array.new
    page = 1
    while true
      response_apartments = HtmlParser.apartments(@client.get("#{@url}&page=#{page}").body)
      if (response_apartments.size == 0)
        break
      end
      apartments = apartments.concat(response_apartments)
      page = page + 1
    end

    puts "#{apartments.size} apartments for query."
    hrefs = apartments.map { |apartment| apartment[:href] }
    # A different query might already have the apartment
    known_hrefs = Apartment.where(href: hrefs).pluck('href').to_set()
    puts "#{known_hrefs.size}/#{apartments.size} apartments already known."
    new_apartments = apartments.filter { |apartment| !known_hrefs.include?(apartment[:href]) }

    # Reverse the apartments so that the first apartments gets saved last and becomes the most recent apartment
    query.apartments << new_apartments.map { |apartment| Apartment.new(href: apartment[:href]) }.reverse

    query.save()

    ApartmentMailer.with(apartments: new_apartments, to: @mail, url: @url).apartment_email.deliver_now
  end
end

if ARGV.size == 2
  Scraper.new(ARGV[0], ARGV[1]).scrape()
else
  puts "USAGE: bin/rails runner scrape.rb <YOUR_MAIL_ADDRESS> <SUUMO_URL>"
end
