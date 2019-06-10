require 'pry'
require 'yaml'
require 'selenium-webdriver'

pages = ARGV[0].to_i
link = ARGV[1]

driver = Selenium::WebDriver.for(:chrome, {args: ['headless']})

team_links = []
pages.times do |page_number|
    page = page_number + 1
    driver.get("#{link}/participants?page=#{page}")

    teams = driver.find_elements(css: '.size-1-of-4')

    teams.each do |team|
        match = /href\s*=\s*"([^"]*)"/.match team.attribute('innerHTML')
        match = match[1]
        match.slice!(0,1)
        match.slice!(-1, 1)

        team_links << match
    end
end

teams = []
team_links.each do |link|
    driver.get "https://www.toornament.com/#{link}/info"
    selector = '#main-container > div.layout-section.content > section > div > div:nth-child(2) > div'

    team_hash = Hash.new
    team_name = driver.find_elements(css: 'h3').first.text
    players = driver.find_elements(css: 'div.text.bold').map {|e|e.text}.compact

    team_hash[:players] = []
    team_hash[:name]    = team_name

    players.size.times do |n|
        team_hash[:players] << players[n]
    end

    teams << team_hash
end

File.open('teams.yml', 'a+') { |f| f.puts teams.to_yaml }

# #TODO teams for today are: message
# teams.each_with_object('') do |team|
#     "team[:name]"
# end

