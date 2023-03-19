# -*- encoding: utf-8 -*-
require 'httpclient'
require 'hpricot'

class HtmlParser
  @@house = '.cassetteitem'
  @@apartment = 'tbody'
  @@href = '.js-cassette_link_href'
  @@address = '.cassetteitem_detail-col1'
  @@age = '.cassetteitem_detail-col3 div:nth-child(1)'
  @@stories = '.cassetteitem_detail-col3 div:nth-child(2)'
  @@rent = '.cassetteitem_price--rent'
  @@layout = '.cassetteitem_madori'
  @@size = '.cassetteitem_menseki'

  def self.address(house)
    # 東京都国分寺市日吉町１
    return house.search(@@address).inner_text
  end

  NEW_CONSTRUCTION = '新築'
  def self.age(house)
    # 築30年 -> 30
    # 新築 -> 0
    text = house.search(@@age).inner_text
    if text == NEW_CONSTRUCTION
      return 0
    end
    match = text.match(/築(\d+)年/)
    if match == nil
      # TODO Send error email to suumomailer@gmail.com
      return nil
    end
    return match[1].to_i
  end
  BASEMENT = '地下'
  def self.stories(house)
    # 2階建 -> 2
    # 地下1地上5階建 -> 5
    # 地下1地上5階建 (1 basement, 5 floors above ground)
    # Ignoring basement floors for now. Maybe add another column for them.
    # Maybe there are also basement-only houses.
    text = house.search(@@stories).inner_text
    match = text.match(/(\d+)階建/)
    if match == nil
      # TODO Send error email to suumomailer@gmail.com
      return nil
    end
    return match[1].to_i
  end

  def self.href(apartment)
    # Two apartments of the same house have random jnc_ and bc= values
    # https://suumo.jp/chintai/jnc_000036589660/?bc=100318741343
    return "https://suumo.jp/#{apartment.search(@@href).attr("href")}"
  end
  def self.rent(apartment)
    # 4.6万円 -> 4.6
    return apartment.search(@@rent).inner_text.to_f
  end
  def self.size(apartment)
    # 55.77m2 -> 55.77
    return apartment.search(@@size).inner_text.to_f
  end
  def self.layout(apartment)
    # 3DK
    return apartment.search(@@layout).inner_text
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
      result.push({
                    address: HtmlParser.address(house),
                    age: HtmlParser.age(house),
                    stories: HtmlParser.stories(house),
                    href: HtmlParser.href(highest_rent_apartment),
                    rent: highest_rent,
                    size: HtmlParser.size(highest_rent_apartment),
                    layout: HtmlParser.layout(highest_rent_apartment),
                  })
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

    isNewQuery = Query.find_by(url: @url) == nil
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

    puts "#{apartments.size} apartments for query"
    hrefs = apartments.map { |apartment| apartment[:href] }
    # A different query might already have the apartment
    known_hrefs = Apartment.where(href: hrefs).pluck('href').to_set()
    puts "#{apartments.size - known_hrefs.size}/#{apartments.size} apartments are new"
    new_apartments = apartments.filter { |apartment| !known_hrefs.include?(apartment[:href]) }

    # Reverse the apartments so that the first apartments gets saved last and becomes the most recent apartment
    query.apartments << new_apartments.map { |apartment| Apartment.new(apartment) }.reverse

    query.save()

    if (isNewQuery)
      puts "Not sending email to #{@mail} - New query"
      return
    end
    ApartmentMailer.with(apartments: new_apartments, to: @mail, url: @url).apartment_email.deliver_now
  end
end

if ARGV.size == 2
  Scraper.new(ARGV[0], ARGV[1]).scrape()
else
  puts "USAGE: bin/rails runner scrape.rb <YOUR_MAIL_ADDRESS> <SUUMO_URL>"
end
