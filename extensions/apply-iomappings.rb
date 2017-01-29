# ansible-playbook -v -i hosts extensions/play_maintenance.yml -e 'ruby_script=./file_metadata.rb'

# NOTE: this assumes that the files itself have not changed.
# thus it's relatively fast because the files metadata is saved in DB.

# maps = IoMapping.where(io_interface_id: 'file_meta_data_mappings')
maps = IoMapping.all
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

      # create new metadatum with mapped value(s)
      md_attr = {
        created_by: e.media_file.uploader,
        meta_key: mk,
        media_entry: e
      }

      if m.key_map_type != 'MetaDatum::Keywords'
        MetaDatum::Text.create!(md_attr.merge(string: v))
      else
        terms = if v.is_a?(Enumerable) then v
        else
          v.to_s.split(',').map(&:strip)
        end

        kws = terms.map do |term|
          term = Keyword.find_or_create_by!(term: term, meta_key: mk)
        end
        mdkw = MetaDatum::Keywords.new(md_attr.merge(keywords: kws))
        mdkw.meta_data_keywords.each do |mdk|
          mdk.created_by = e.media_file.uploader
        end
        mdkw.save!
      end

    end
  end
end
