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

class DuplicateFinder
  # Maybe allow some small differences. The same apartment might get 50.13m and 50m in two different listings
  # With SIZE_STEP = 2: 0m,2m,4m,6m
  # SIZE_STEP = 2
  # rounded_size = (apartment[:size] / SIZE_STEP).round * SIZE_STEP
  def self.hash_id(apartment)
    return "#{apartment[:address]},#{apartment[:age]},#{apartment[:stories]},#{apartment[:rent]},#{apartment[:size]},#{apartment[:layout]}"
  end
  def self.hash_id_set(apartments)
    set = Set.new
    apartments.each { |apartment| set.add(DuplicateFinder.hash_id(apartment)) }
    return set
  end

  # Or I add apartments 1 by 1 to db and just always check against db? no ineffient
  # What if I make the hash the primary key? then i would loose the duplicates. I actually want to save the duplicates! and have second table to group them to have multiple options to call
  # So I should not remove them here but group them?
  # Second table groupname is the hash? Maybe no second table needed then?
  # Save all new apartments don't even check duplicates, then for each apartment check if there is a hash with in the db (after saving all hashes in db + inefficient. pluck href and hash)
  def self.complement(apartments, not_in)
    return apartments.filter { |apartment| !not_in.include?(DuplicateFinder.hash_id(apartment)) }
  end
  def self.deduplicate(apartments)
    seen = Set.new
    unique_apartments = Array.new
    apartments.each do |apartment|
      hash_id = DuplicateFinder.hash_id(apartment)
      if !seen.include?(hash_id)
        unique_apartments.push(apartment)
        seen.add(hash_id)
      end
    end
    return unique_apartments
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

    puts "#{apartments.size} apartments"
    known = Apartment.pluck('href', 'hash_id')
    known_hrefs = known.map { |known| known[0] }.to_set()
    known_hash_ids = known.map { |known| known[1] }.to_set()

    # An apartment might have already been saved by a different Query -> Check all apartments from db
    # Saving duplicate apartments to the db to list them in a UI
    save_apartments = apartments
                        .filter { |apartment| !known_hrefs.include?(apartment[:href]) }
                        .map { |apartment| apartment[:hash_id] = DuplicateFinder.hash_id(apartment); apartment }

    # Reverse the apartments so that the first apartments gets saved last and becomes the most recent apartment
    query.apartments << save_apartments
                          .map { |apartment| Apartment.new(apartment) }
                          .reverse
    query.save()
    puts "#{save_apartments.size}/#{apartments.size} apartments saved"

    if (isNewQuery)
      puts "Not sending email to #{@mail} - New query"
      return
    end

    new_to_db = DuplicateFinder.complement(save_apartments, known_hash_ids)
    new_to_db_unique = DuplicateFinder.deduplicate(new_to_db)
    ApartmentMailer.with(apartments: new_to_db_unique, to: @mail, url: @url).apartment_email.deliver_now
  end
end

if ARGV.size == 2
  Scraper.new(ARGV[0], ARGV[1]).scrape()
else
  puts "USAGE: bin/rails runner scrape.rb <YOUR_MAIL_ADDRESS> <SUUMO_URL>"
end
