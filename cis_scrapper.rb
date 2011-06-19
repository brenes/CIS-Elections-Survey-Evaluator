require 'rubygems'
require 'nokogiri'
require 'open-uri'

# SOME CONFIG STUFF ###########################################################

survey_urls = {
  "Aragón" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2687/e268700.html",
  "Asturias" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2688/e268800.html",
  "Baleares" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2689/e268900.html",
  "Canarias" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2690/e269000.html",
  "Cantabria" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2691/e269100.html",
  "Catilla-La Mancha" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2692/e269200.html",
  "Castilla-Leon" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2693/e269300.html",
  "Comunidad Valenciana" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2694/e269400.html",
  "Extremadura" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2695/e269500.html",
  "La Rioja" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2699/e269900.html",
  "Madrid" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2696/e269600.html",
  "Murcia" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2697/e269700.html",
  "Navarra" => "http://www.cis.es/cis/opencms/-Archivos/Marginales/2680_2699/2698/e269800.html"
  }

# xpath_voting_expression = "//body/font[1]/table[8]/tr//tr"
xpath_voting_expression = "//body//table[8]/tr//tr"

# each line of the voting table must fit in one of the following groups

label_categories = {
  #   - PP, PSOE, CIU and PNV have their own group
  "PP" => "PP",
  "UPN" => "PP",  # PP presented under UPN name in Navarra
  "PSOE" => "PSOE",
  "CIU" => "CIU",
  "PNV" => "PNV",
  
  #   - Blank votes have their own category
  "En blanco" => "blank",
  "No votaría" => "blank",
}

  #   - No category: NS/NC
no_category = ["No sabe todavía", "N.C.", "TOTAL"]

#   - everyhing else goes to "other" category as corresponds to other parties

# LET'S GO ####################################################################

global_data = {}

# we first download each survey
survey_urls.each do |survey_zone, survey_url|

  categories = {}

  puts "Downloading #{survey_url}"
  survey_web = Nokogiri::HTML(open(survey_url))

  # now we grab the results
  results = survey_web.xpath(xpath_voting_expression)

  puts "#{results.count} opciones de voto posibles"

  # for each result we must categorize it
  results.each do |result|
    
    fonts = result.xpath(".//font")
    result = {:type => fonts[0].content.strip, 
      :value => fonts[1].content.strip.to_f}
        
    if label_categories[result[:type]].nil?
      unless no_category.include?(result[:type])
        categories["other"] ||= 0
        categories["other"] += result[:value]  
      end
    else
      categories[label_categories[result[:type]]] ||= 0
      categories[label_categories[result[:type]]] += result[:value]
    end

  end

  total_votes = categories.values.inject(0){|v, total| v+total}
  global_data[survey_zone] = {}

  categories.each do |category, value|
    global_data[survey_zone][category] = value * 100 / total_votes
  end

  puts "#{survey_zone }--> #{global_data[survey_zone].inspect}"
end
puts "************* RESULTADOS *****************"
puts "zone|#{global_data.values.first.keys.join("|")}"
global_data.each do |zone, results|
  puts "#{zone}|#{results.values.join("|")}"
end