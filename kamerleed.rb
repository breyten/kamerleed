#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'json'

require 'sinatra'
require 'httparty'

enable :sessions

def random_member(members)
  mp_id = session['mp_id'] || '0'
  if mp_id.to_i > 0
    old_mp = members.select { |mp| mp['id'] == mp_id }[0]
    filtered_members = members.select { |mp| (mp['id'] != mp_id) && (mp['blockId'] != old_mp['blockId']) && (mp['party']['id'] != old_mp['party']['id']) }
  else
    filtered_members = members
  end
  kamerlid = filtered_members[rand(filtered_members.length)]

  return kamerlid
end

def find_member(slug, members)
  filtered_members = members.select { |mp| mp['slug'] == slug }
  return filtered_members[0]
end

def seniority(kamerlid)
  title = kamerlid['title']
  seniority = kamerlid['seniority'].to_i

  return "%s zit al %s dagen in de tweede kamer!" % [title, seniority]
end

def age(kamerlid)
  title = kamerlid['title']
  age = kamerlid['age'].to_i

  return "Wist je dat %s alweer %s jaar oud is?" % [title, age]
end

def hometown(kamerlid)
  title = kamerlid['title']
  hometown = kamerlid['hometown']

  return "Blijkbaar woont %s in %s!" % [title, hometown]
end

def birthplace(kamerlid)
  title = kamerlid['title']
  birthplace = kamerlid['birthplace']

  return "%s werd geboren in %s." % [title, birthplace]
end

def load_mps
  members = []
  File.open('kamerleden.json', 'r') do |f|
    members = JSON.parse(f.read)
  end
  
  return members
end

def load_parties
  parties = []
  File.open('parties.json', 'r') do |f|
    parties = JSON.parse(f.read)
  end
  
  return parties
end

def get_details(mps)
  options = ['seniority', 'age', 'hometown', 'birthplace']

  details = {
    :mp => random_member(mps),
    :function => options[Random.rand(options.length)]
  }
  details[:sentence] = send(details[:function], details[:mp])

  session['mp_id'] = details[:mp]['id']

  return details
end

get '/' do
  @members = load_mps
  @parties = load_parties

  erb :index
end

get '/persons/random/json' do
  response.headers['Content-type'] = "application/json"
  @members = load_mps
  @details = random_member(@members)

  @details.to_json
end

get '/persons/:slug' do
  response.headers['Content-type'] = "application/json"
  
  @members = load_mps
  @details = find_member(params[:slug], @members)
  
  @details.to_json
end

get '/persons/:slug/json' do
  response.headers['Content-type'] = "application/json"
  
  @members = load_mps
  @details = find_member(params[:slug], @members)
  
  @details.to_json
end


get '/parties/json' do
  response.headers['Content-type'] = "application/json"
  @parties = load_parties

  @parties.to_json
end

get '/update' do
  parties = HTTParty.get('http://api.kamerleed.nl/v2.1/parties/')

  members = parties.map { |party| party["members"] }.flatten
  
  File.open("kamerleden.json","w") do |f|
    f.write(members.to_json)
  end

  File.open("parties.json","w") do |f|
    f.write(parties.to_json)
  end
end