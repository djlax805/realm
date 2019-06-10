require 'pry'
require 'yaml'
require 'digest'
require 'httparty'
require 'discordrb'

creds = YAML.load_file '../secrets.yml'
DEV_ID = creds[:dev_id]
AUTH_KEY = creds[:auth_key]

def make_sig method, timestamp
    Digest::MD5.hexdigest(
        DEV_ID +
        method +
        AUTH_KEY +
        timestamp
    )
end

def base_url method, sig
    "http://api.realmroyale.com/realmapi.svc/" +
    method +
    '/'    +
    DEV_ID +
    '/'    +
    sig    +
    '/'
end


timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')

sig = make_sig 'createsession', timestamp
session_url = base_url('CreateSessionJSON', sig) + timestamp
response = HTTParty.get session_url
session_id = response['session_id']


players = YAML.load_file 'players.yml'

lobbies = {}

players.each do |player|
    begin
        name = URI.escape player
        player_uri = "#{session_id}/#{timestamp}/#{name}"

        sig = make_sig 'searchplayers', timestamp
        search_uri = base_url('SearchPlayersJSON', sig)
        response = HTTParty.get search_uri + player_uri

        player_id = response.first['id'].to_s
        next unless player_id


        sig = make_sig 'getplayerstatus', timestamp
        status_uri = base_url('GetPlayerStatusJSON', sig)
        response = HTTParty.get status_uri + player_uri

        match_id = response['match_id']

        #skip since they aren't in a game
        next if match_id == 0

        game = lobbies[match_id]

        if game.nil?
            lobbies[match_id] = [team[:name]]
        else
            lobbies[match_id] = game << team[:name]
        end
    rescue
        puts name
        next
    end
end

#   for each lobbie
#       for each team
    #       find players
bot = Discordrb::Bot.new(token: '', client_id: )
lobbies.each_with_index do |game, i|
    fields = game[1].map do |team_name|
        players = teams.select {|team| team[:name] == team_name}.first[:players]
        player_string = players.join("\n")

        {
            name: team_name, value: player_string, inline:true
        }
    end

    bot.send_message(, '', false, {
    color: 3447003,
    fields: fields
    })
end

bot.run

# # i made a bot that gathers the lobbies for the realm comm, if it's accurate and u want it to help verify matches (min teams per lobby) and for the players to see who is in their game then you can give mehistory
