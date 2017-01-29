# ansible-playbook -v -i hosts extensions/play_maintenance.yml -e 'ruby_script=./file_metadata.rb'

# NOTE: this assumes that the files itself have not changed.
# thus it's relatively fast because the files metadata is saved in DB.

maps = IoMapping.where(io_interface_id: 'file_meta_data_mappings')
mapped_keys = maps.map(&:key_map).uniq

# for file metadata of all media entries,
MediaEntry.all.each do |e|
  e.media_file.meta_data.each do |k, v|
    maps.where(key_map: k).each do |m|
      # map meta key,
      mk = MetaKey.find_by(id: m.meta_key_id)
      next unless mk
      # don't overwrite any exiting data,
      next if MetaDatum.find_by(meta_key: mk, media_entry: e)
      # create new metadatum with mapped text value
      MetaDatum::Text.create!(
        string: v,
        created_by_id: e.media_file.uploader_id,
        meta_key: mk,
        media_entry: e)
    end.compact
  end
end
