#!/usr/bin/env ruby

require 'rubygems'
require 'json'

login = `git config github.user`.chomp
token = `git config github.token`.chomp
if token[0,1] == '!'
  token = `#{token[1..-1]}`
end
login = nil if login == ''
token = nil if token == ''

unless login and token
  puts "Set up login and token in git config"
  exit 1
end

repo_name = ARGV[0]
unless repo_name
  puts "Provide repo name to create"
  exit 2
end

response = `curl -s -F 'name=#{repo_name}' -F 'login=#{login}' -F 'token=#{token}' http://github.com/api/v2/json/repos/create`
response = JSON.parse(response)

if response.has_key?('error')
  puts "error: #{response['error']}"
  exit 3
end
