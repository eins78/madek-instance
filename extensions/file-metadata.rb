# ansible-playbook -v -i hosts extensions/play_maintenance.yml -e 'ruby_script=./file_metadata.rb'

require 'yaml'

data = <<-YAML
  - id: filename
    title: Filename
    mappings:
    - Filename

  - id: iptc_city
    title: City
    type: keyword
    mappings:
    - IPTC:City

  - id: province_state
    title: Province/State
    type: keyword
    mappings:
    - IPTC:Province-State

  - id: country_code
    title: Country Code
    type: keyword
    mappings:
      - XMP-iptcCore:CountryCode
      - IPTC:Country-PrimaryLocationCode

  - id: image_width
    title: Image Width
    mappings:
    - File:ImageWidth

  - id: image_height
    title: Image Height
    mappings:
    - File:ImageHeight

  - id: exif_aperture_value
    title: Camera Aperture Value
    type: keyword
    mappings:
    - ExifIFD:ApertureValue

  - id: exif_focal_length
    title: Camera Focal Length
    description: Focal Length (in 35mm format)
    type: keyword
    mappings:
    - ExifIFD:FocalLengthIn35mmFormat

  - id: exif_exposure_time
    title: Camera Exposure Time
    type: keyword
    mappings:
    - ExifIFD:ExposureTime

  - id: exif_iso
    title: Camera ISO
    type: keyword
    mappings:
    - ExifIFD:ISO

  - id: exif_lens_info
    title: Camera Lens Info
    type: keyword
    mappings:
    - ExifIFD:LensInfo

  - id: exif_lens_make
    type: keyword
    title: Camera Lens Make
    mappings:
    - ExifIFD:LensMake

  - id: exif_lens_model
    type: keyword
    title: Camera Lens Model
    mappings:
    - ExifIFD:LensModel

  - id: gps_latitude_ref
    title: GPS LatitudeRef
    mappings:
    - GPS:GPSLatitudeRef

  - id: gps_latitude
    title: GPS Latitude
    mappings:
    - GPS:GPSLatitude

  - id: gps_longitude_ref
    title: GPS LongitudeRef
    mappings:
    - GPS:GPSLongitudeRef

  - id: gps_longitude
    title: GPS Longitude
    mappings:
    - GPS:GPSLongitude

  - id: gps_altitude_ref
    title: GPS AltitudeRef
    mappings:
    - GPS:GPSAltitudeRef

  - id: gps_altitude
    title: GPS Altitude
    mappings:
    - GPS:GPSAltitude

  - id: gps_positioning_error
    title: GPS HPositioningError
    mappings:
    - GPS:GPSHPositioningError

  - id: is_merged_panorama
    title: Camera merged Panorama
    type: keyword
    mappings:
    - XMP-aux:IsMergedPanorama

YAML

keys = YAML.safe_load data

v = Vocabulary.find_or_create_by!(id: 'file_meta_data')
v.update_attributes!(
  label: 'File MetaData',
  description: 'Read-only MetaData mapped from data embedded in the uploaded file',
  enabled_for_public_view: true,
  enabled_for_public_use: false)

i = IoInterface.find_or_create_by!(id: 'file_meta_data_mappings')

keys.sort_by {|k| k['id']}.each.with_index do |k, n|
  mkid = "#{v.id}:#{k['id']}"
  is_keyword = k['type'] == 'keyword'
  MetaKey.find_or_create_by!(
    id: mkid,
    vocabulary: v,
    meta_datum_object_type: is_keyword ? 'MetaDatum::Keywords' : 'MetaDatum::Text')
    .update_attributes!(
      position: n,
      label: k['title'],
      admin_comment: k['admin_comment'],
      hint: "Maps from: #{k['mappings'].join(', ')}")

  k['mappings'].each do |m|
    IoMapping.find_or_create_by!(
      meta_key_id: mkid,
      key_map: m,
      io_interface: i,
      key_map_type: is_keyword ? 'MetaDatum::Keywords' : nil,
    )
  end
end
