# usage:
# you need ruby installed to use that script
# then copy this file in a folder and open your terminal
# the first time install the mechanize gem by typing
# gem install 'mechanize'
# then for running the script type
# ruby get_meetup_member.rb url_of_the_meetup_members_page_here
# example: ruby get_meetup_member.rb http://www.meetup.com/fr-FR/Club-Digital-Paris/members/

require 'mechanize'
require 'csv'

@url = ARGV.first
@members = []

if (@url =~ /\/members\/$/).nil?
  puts "Wrong url format (should end with /members/)."
  puts "To launch this script run your query as in:"
  puts "ruby get_meetup_member.rb http://www.meetup.com/fr-FR/Club-Digital-Paris/members/"
  puts "Please try again."
  abort
end

def get_members(page)
  @members << page.search(".member-details h4 a").map{ |url| url.attributes['href'].text.scan(/(\d+)\/$/).first.last.to_i }
  @members.flatten!(1)
  puts "url found: #{@members.count}"
end

def save_member_details(page, id)
  puts "getting data for member id #{id}"
  member = []
  member[0] = id
  member[1] = @page.search("h1 span.fn").text rescue nil
  member[2] = @page.search("span.locality").text rescue nil
  member[3] = @page.search(".D_memberProfileContentItem").last.text.gsub("\n\nBio\n\n","") rescue nil

  @page.search(".D_memberProfileSocial li a").each do |network|
    case network.attributes['title'].text.gsub(/: @.*/,"")
      when "Twitter"
        member[4] = network.attributes['href'].text
      when "Facebook"
        member[5] = network.attributes['href'].text
      when "Linkedin"
        member[6] = network.attributes['href'].text
      when "Tumblr"
        member[7] = network.attributes['href'].text
      when "Flickr"
        member[8] = network.attributes['href'].text
    end
  end
  CSV.open("meetup_members.csv", "a+") { |csv| csv << member }
end

puts "----------------------------------"
puts "Let's go ! We'll scrape members of #{@url}"
puts "----------------------------------"

# start mechanize
@mechanize = Mechanize.new
@page = @mechanize.get @url
get_members(@page)

# get max offset from last navigation link
max_offset = @page.at(".nav-next").attributes['href'].text.scan(/offset=(\d+)&/).first.last.to_i
pages = max_offset/20
offsets = pages.times.map { |i| i*20 } - [0]

# open each pagination and scrape members
offsets.each do |offset|
  next_page = "#{@url}/?offset=#{offset}&sort=last_visited&desc=1"
  @page = @mechanize.get next_page
  get_members(@page)
end

# open each profiles and write info to csv file
@members.each do |id|
  url = "https://www.meetup.com/members/#{id}/"
  @page = @mechanize.get url
  save_member_details(@page, id)
end