require 'rubygems'
require 'nokogiri'
require 'open-uri'

# SOME CONFIG STUFF ###########################################################

result_urls = {
  "Aragón" => "http://resultados.elpais.com/elecciones/2007/autonomicas/02/index.xml2",
  "Asturias" => "http://resultados.elpais.com/elecciones/2007/autonomicas/03/index.xml2",
  "Baleares" => "http://resultados.elpais.com/elecciones/2007/autonomicas/04/index.xml2",
  "Canarias" => "http://resultados.elpais.com/elecciones/2007/autonomicas/05/index.xml2",
  "Cantabria" => "http://resultados.elpais.com/elecciones/2007/autonomicas/06/index.xml2",
  "Catilla-La Mancha" => "http://resultados.elpais.com/elecciones/2007/autonomicas/07/index.xml2",
  "Castilla-Leon" => "http://resultados.elpais.com/elecciones/2007/autonomicas/08/index.xml2",
  "Comunidad Valenciana" => "http://resultados.elpais.com/elecciones/2007/autonomicas/17/index.xml2",
  "Extremadura" => "http://resultados.elpais.com/elecciones/2007/autonomicas/10/index.xml2",
  "La Rioja" => "http://resultados.elpais.com/elecciones/2007/autonomicas/16/index.xml2",
  "Madrid" => "http://resultados.elpais.com/elecciones/2007/autonomicas/12/index.xml2",
  "Murcia" => "http://resultados.elpais.com/elecciones/2007/autonomicas/15/index.xml2",
  "Navarra" => "http://resultados.elpais.com/elecciones/2007/autonomicas/13/index.xml2"
  }

xpath_parties_expression = "//partido"
xpath_votes_number_expression = "//votos/contabilizados/cantidad"
xpath_invalid_votes_number_expression = "//votos/nulos/cantidad"
xpath_no_votes_number_expression = "//votos/abstenciones/cantidad"
xpath_blank_votes_number_expression = "//votos/blancos/cantidad"

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
result_urls.each do |result_zone, result_url|

  results = {}

  puts "Downloading #{result_url}"
  result_web = Nokogiri::HTML(open(result_url))

  # now we grab the global statistics
  votes_number = result_web.xpath(xpath_votes_number_expression).first.content.to_f
  invalid_votes_number = result_web.xpath(xpath_invalid_votes_number_expression).first.content.to_f
  no_votes_number = result_web.xpath(xpath_no_votes_number_expression).first.content.to_f
  blank_votes_number = result_web.xpath(xpath_blank_votes_number_expression).first.content.to_f
  total_people = votes_number + no_votes_number - invalid_votes_number

  parties = result_web.xpath(xpath_parties_expression)

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

  global_data[result_zone] = {}

  results.each do |category, value|
    global_data[result_zone][category] = value / total_people
  end

  puts "#{result_zone }--> #{results.inspect}"
end
puts "************* RESULTADOS *****************"
puts "zone|#{global_data.values.first.keys.join("|")}"
global_data.each do |zone, results|
  puts "#{zone}|#{results.values.join("|")}"
end