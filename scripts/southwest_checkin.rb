#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'

MY_NAME = 'Yossef Mendelssohn'
CHECKIN_REQUEST_URL = 'http://www.southwest.com/content/travel_center/retrieveCheckinDoc.html?ref=ckin_hp_wl_tt'
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

agent = WWW::Mechanize.new
agent.user_agent_alias = 'Mac Mozilla'

checkin_request_page = agent.get(CHECKIN_REQUEST_URL)
checkin_request_form = checkin_request_page.form_with(:action => '/cgi-bin/selectBoardingPass')
checkin_request_form.recordLocator = conf
checkin_request_form.firstName = name.first
checkin_request_form.lastName  = name.last
checkin_page = checkin_request_form.submit
error = (checkin_page / 'span#whatHappened').first

if error
  puts if prompt
  puts "Could not check in."
  puts error.content
  exit
end

checkin_form = checkin_page.form_with(:action => '/cgi-bin/viewBoardingPass')
checkin_form.checkboxes.each { |box|  box.check }
boarding_page = checkin_form.submit

puts if prompt
puts "Successfully checked in, got"

boarding_names = boarding_page / 'span.bpPaxName'
boarding_names.each do |span|
  boarding_info = span.parent.parent.parent / 'td.bpBoardingGroupLabel img'
  boarding_position = boarding_info.collect { |x| x.attributes['src'].to_s.match(/(\w).gif$/)[1] }.join
  puts "#{span.content} - #{boarding_position}"
end
