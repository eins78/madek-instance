# ansible-playbook -v -i hosts extensions/play_maintenance.yml -e 'ruby_script=./import-iso-country-codes.rb'

# to use it:
# - run `file-metadata.rb` to create an iomapping for the used key
# - run `apply-iomappings.rb` to map country codes from file metadata (IPTC)

# FIXME: no https???
DATA_URL = 'http://download.geonames.org/export/dump/countryInfo.txt'
BASE_URL = 'http://geonames.org/countries'

# get data
countries = `curl '#{DATA_URL}'`.chomp
  .split("\n")
  .reject { |line| line.start_with? '#' }
  .map {|line| line.split "\t" }
  .map {|fields| {code: fields[0], name: fields[4]}}

# meta
vocab = Vocabulary.find_or_create_by!(id: 'geo', label: 'Geo')
mkey = MetaKey.find_or_create_by!(
  id: 'file_meta_data:country_code',
  vocabulary_id: 'file_meta_data'
)
mkey.update_attributes!(
  label: 'Country Code',
  description: 'Country by ISO Country Code',
  hint: 'Two-letter country code from the ISO-3166 list',
  meta_datum_object_type: 'MetaDatum::Keywords',
  allowed_rdf_class: 'Country',
  is_extensible_list: false,
  is_enabled_for_media_entries: true
)
type = RdfClass.find_or_create_by!(id: 'Country')
type.update_attributes!(
  description: 'same as <http://schema.org/Country>'
)

# add countries
countries.each do |country|
  kw = Keyword.find_or_create_by!(term: country[:code], meta_key_id: mkey.id)
  kw.update_attributes!(
    rdf_class: 'Country',
    description: country[:name],
    external_uri: "#{BASE_URL}/#{country[:code]}/"
  )
end
