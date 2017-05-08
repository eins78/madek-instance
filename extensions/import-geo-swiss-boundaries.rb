# encoding: UTF-8

API_BASE = 'https://ld.geo.admin.ch/query'

feature_types = {
  canton: {
    label: 'Kanton',
    description: 'Schweizer Kanton',
    geonames_code: 'A.ADM1',
    type_description: 'geonames.org: "first-order administrative division, a primary administrative division of a country, such as a state in the United States"'
  },
  district: {
    label: 'Region',
    description: 'Bezirk, Verwaltungseinheit, Wahlkreis, Amtei, Amt oder statistische Einheit zwischen Kanton und Gemeinde',
    geonames_code: 'A.ADM2',
    type_description: 'geonames.org: "second-order administrative division, a subdivision of a first-order administrative division"'
  },
  municipality: {
    label: 'Gemeinde',
    description: 'Schweizer Gemeinde',
    geonames_code:'A.ADM3',
    type_description: 'geonames.org: "third-order administrative division, a subdivision of a second-order administrative division"'
  }
}

vocab = Vocabulary.find_or_create_by!(id: 'swiss_geo')
vocab.update_attributes!(
  label: 'Swiss Geo',
  description: 'Linked Data Vokabular mit "swissBOUNDARIES 3D"-GeoDaten des Schweizer Bundesamtes für Landestopografie (<http://geo.admin.ch>)')

feature_types.each do |key, feature|

  type = RdfClass.find_or_create_by!(id: key.to_s.classify)
  type.update_attributes!(description: feature[:type_description])

  mkey = MetaKey.find_or_create_by!(id: "#{vocab.id}:#{key}", vocabulary_id: vocab.id)
  mkey.update_attributes!(
    label: feature[:label],
    description: feature[:description],
    meta_datum_object_type: 'MetaDatum::Keywords',
    allowed_rdf_class: type,
    is_extensible_list: false,
    is_enabled_for_media_entries: true)

  sqarql = <<-SPARQL.strip_heredoc.chomp.strip
    SELECT ?Place ?Name WHERE {
      ?Place a <http://schema.org/AdministrativeArea> . #specify only the non-versioned entries.
      ?Place <http://schema.org/name> ?Name .
      ?Place a <http://www.geonames.org/ontology##{feature[:geonames_code]}> .
    }
    ORDER BY ?Name
  SPARQL

  data = JSON.parse(
    `curl '#{API_BASE}' -H 'Accept: application/json' -X POST --data '#{{query: sqarql}.to_query}'`)

  places = data['results']['bindings'].map do |h|
    data['head']['vars'].map {|v| [v.underscore, h[v]['value']] }.to_h
  end

  # { # a place:
  #   "place": "https://ld.geo.admin.ch/boundaries/canton/24",
  #   "name": "Neuchâtel",
  #   "wikidata_uri": "http://www.wikidata.org/entity/Q68451",
  #   "geo_names_uri": "http://sws.geonames.org/7285364/"
  # }

  # uniq: ignore duplicate mappings to geonames etc
  # group by because names themselves are also not uniq
  pl = places.uniq { |p| p['place'] }.group_by { |p| p['name'] }.sort_by(&:first).map do |name, list|
    list.sort_by { |p| p['place'] }.map.with_index do |place, index|
      name = "#{name} [#{index + 1}]" if index > 0
      kw = Keyword.find_or_initialize_by(term: name, meta_key_id: mkey.id)
      kw.update_attributes(rdf_class: type, external_uri: place['place'], position: 0)
      kw.save!
      kw
    end
  end

end
