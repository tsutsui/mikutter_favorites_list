# -*- coding: utf-8 -*-

Plugin.create(:favorites_list) do

  UserConfig[:favorites_list_retrieve_count_own_favorites] ||= 20

  module MikuTwitter::APIShortcuts
    defshortcut :favorites_list, 'favorites/list', :messages
  end

  mix_tl_tab = tab :own_fav_tl, "お気に入り" do
    set_icon Skin.get("unfav.png")
    timeline :own_fav_tl
  end

  settings('お気に入り') do
    settings('一度に取得するつぶやきの件数(1-200)') do
      adjustment('自分のお気に入り', :favorites_list_retrieve_count_own_favorites, 1, 200)
    end
  end

  on_boot do |service|
    user = service.user_obj
    service.favorites_list(user_id: user[:id], count: [UserConfig[:favorites_list_retrieve_count_own_favorites], 200].min).next{ |tl|
      timeline(:own_fav_tl) << tl
    }.terminate("@#{user[:idname]} のお気に入りが取得できませんでした。")
  end

end

