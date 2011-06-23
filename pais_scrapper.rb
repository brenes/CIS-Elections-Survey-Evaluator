require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'yaml'

# LOADING CONFIG STUFF ########################################################

settings = YAML::load( File.open( 'settings.yml' ) )

# each line of the voting table must fit in one of the following groups

label_categories = {
  #   - PP, PSOE, CIU and PNV have their own group
  "PP" => "PP",
  "UPN" => "PP",  # PP presented under UPN name in Navarra
  "PSOE" => "PSOE",
  "PSN-PSOE" => "PSOE",
  "CIU" => "CIU",
  "PNV" => "PNV"
}

#   - everyhing else goes to "other" category as corresponds to other parties

# LET'S GO ####################################################################

global_data = {}

# we first download each result
settings["results"].each do |result_key, result_zone|

  results = {}

  puts "Downloading #{result_zone["name"]} #{result_zone["url"]}"
  result_web = Nokogiri::HTML(open(result_zone["url"]))

  # now we grab the global statistics
  votes_number = result_web.xpath(result_zone["xpath"]["votes_number_expression"]).first.content.to_f
  invalid_votes_number = result_web.xpath(result_zone["xpath"]["invalid_votes_number_expression"]).first.content.to_f
  no_votes_number = result_web.xpath(result_zone["xpath"]["no_votes_number_expression"]).first.content.to_f
  blank_votes_number = result_web.xpath(result_zone["xpath"]["blank_votes_number_expression"]).first.content.to_f
  total_people = votes_number + no_votes_number - invalid_votes_number

  parties = result_web.xpath(result_zone["xpath"]["parties_expression"])

  puts "#{parties.count} opciones de voto posibles"

  # for each result we must categorize it
  parties.each do |party|
    
    party = {:name => party.xpath("nombre")[0].content, 
      :votes => party.xpath("votos_numero")[0].content.to_f}
        puts party.inspect
    if label_categories[party[:name]].nil?
        results["other"] ||= 0
        results["other"] += party[:votes] 
    else
      results[label_categories[party[:name]]] ||= 0
      results[label_categories[party[:name]]] += party[:votes]
    end

  end
  
  results["blank"] = no_votes_number + blank_votes_number

  global_data[result_zone["name"]] = {}

  results.each do |category, value|
    global_data[result_zone["name"]][category] = 100 * value / total_people 
  end

end
puts "************* RESULTADOS *****************"
puts "zone|#{global_data.values.first.keys.join("|")}"
global_data.each do |zone, results|
  puts "#{zone}|#{results.values.join("|")}"
end