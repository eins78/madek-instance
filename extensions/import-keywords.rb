# ansible-playbook -v -i hosts extensions/play_maintenance.yml -e 'ruby_script=./import-keywords.rb'

terms= %w(street sticker streetart Illustration graffiti character face print politics marker propaganda aphorism spraypaint economics tag  typography stencil  advertising screenshot food  poster gentrification tech police SBB  art  bubblestyle cutout animal  linocut zhdk poststicker trainstation internet ToniAreal pasteup freeconomics antifa silkscreen blackletter snake drip piece fraktur football palestine ecology heart shop sign)

  terms.each do |t| Keyword.find_or_create_by!(term: t.to_s.strip, meta_key_id: 'madek_core:keywords') end
