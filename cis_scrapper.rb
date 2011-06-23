require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'yaml'

# LOADING CONFIG STUFF ########################################################

settings = YAML::load( File.open( 'settings.yml' ) )

# LET'S GO ####################################################################

global_data = {}

# we first download each survey
settings["predictions"].each do |survey_key, survey_zone|

  categories = {}

  puts "Downloading #{survey_zone["name"]}: #{survey_zone["url"]}"
  survey_web = Nokogiri::HTML(open(survey_zone["url"]))

  # now we grab the results
  results = survey_web.xpath(survey_zone["xpath"]["voting_expression"])

  puts "#{results.count} opciones de voto posibles"

  # for each result we must categorize it
  results.each do |result|
    
    fonts = result.xpath(".//td")
    result = {:type => fonts[0].content.strip, 
      :value => fonts[1].content.strip.to_f}
        puts result.inspect
    # If it's a party, we include it in its group
    if !settings["labels"]["parties"][result[:type]].nil?

      categories[settings["labels"]["parties"][result[:type]]] ||= 0
      categories[settings["labels"]["parties"][result[:type]]] += result[:value]

    # If it's a blank vote, to the blank group    
    elsif settings["labels"]["blank"].include? result[:type]

      categories["blank"] ||= 0
      categories["blank"] += result[:value]

    # If it's not in the 'no label' group, to the 'others' group

    elsif not(settings["labels"]["no_label"].include? result[:type])

      categories["other"] ||= 0
      categories["other"] += result[:value]  

    end

  end

  # now we normalize, so all those citizen which don't answer are not taken into account
  total_votes = categories.values.inject(0){|v, total| v+total}
  global_data[survey_zone["name"]] = {}

  categories.each do |category, value|
    global_data[survey_zone["name"]][category] = value * 100 / total_votes
  end

end

puts "************* RESULTADOS *****************"
puts "zone|#{global_data.values.first.keys.join("|")}"
global_data.each do |zone, results|
  puts "#{zone}|#{results.values.join("|")}"
end