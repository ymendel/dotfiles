#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'

MY_NAME = 'Yossef Mendelssohn'
CHECKIN_REQUEST_URL = 'http://www.southwest.com/flight/retrieveCheckinDoc.html'
prompt = false

conf = ARGV[0]
unless conf
  prompt = true
  print 'Enter your confirmation number: '
  conf = gets.chomp
end

name = ARGV[1] || MY_NAME
name = name.split(' ')
# print 'Enter your name: '
# name = gets.chomp.split(' ')

agent = Mechanize.new
agent.user_agent_alias = 'Mac Mozilla'

checkin_request_page = agent.get(CHECKIN_REQUEST_URL)
checkin_request_form = checkin_request_page.form_with(:name => 'retrieveItinerary')
checkin_request_form.confirmationNumber = conf
checkin_request_form.firstName = name.first
checkin_request_form.lastName  = name.last
checkin_page = checkin_request_form.submit
error = (checkin_page / 'div#error_wrapper').first

if error
  puts if prompt
  puts "Could not check in."
  puts error.content
  exit
end


checkin_form = checkin_page.form_with(:name => 'checkinOptions')
checkin_form.checkboxes.each { |box|  box.check }
print_button = checkin_form.buttons.detect { |b|  b.name == 'printDocuments' }
boarding_page = checkin_form.click_button(print_button)

puts if prompt
puts "Successfully checked in, got"

boarding_passes = boarding_page / 'div.details'
boarding_passes.each do |pass|
  boarding_name = (pass / 'p.name span').collect { |x|  x.content }.join(' ')
  
  boarding_info = pass / 'div.boardingPosition img'
  boarding_position = boarding_info.collect { |x| x.attributes['src'].to_s.match(/(\w).gif$/)[1] }.join
  
  puts "#{boarding_name} - #{boarding_position}"
end
