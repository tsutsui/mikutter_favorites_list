# -*- coding: utf-8 -*-

favorites_list_retrieve_queue_user = Hash.new

Plugin.create(:favorites_list) do
  UserConfig[:favorites_list_retrieve_count] ||= 20

  module MikuTwitter::APIShortcuts
    defshortcut :favorites_list, 'favorites/list', :messages
  end

  settings('お気に入り') do
    settings('一度に取得するつぶやきの件数(1-200)') do
      adjustment('お気に入り', :favorites_list_retrieve_count, 1, 200)
    end
  end

  tab :own_favorites_list, "お気に入り" do
    set_icon Skin["unfav.png"]
    timeline :own_favorites_list
  end

  profiletab :favorites_list, "お気に入り" do
    set_icon Skin["unfav.png"]
    i_timeline = timeline(nil)
    favorites_list_retrieve_queue_user[i_timeline.slug] = model
  end

  on_retrieve_favorites_list do |service, screen_name, timeline_slugs, options = {}|
    timeline_slugs = [timeline_slugs] if not timeline_slugs.is_a? Array
    options[:screen_name] = screen_name
    service.favorites_list(options).next{ |tl|
      timeline_slugs.each { |slug|
        timeline(slug) << tl
      }
    }.terminate("@#{screen_name} のお気に入りが取得できませんでした。")
  end

  on_boot do |service|
    favorites_list_retrieve_queue_user[:own_favorites_list] = service.user_obj
  end

  on_favorite do |service, user, message|
    if Service.primary.user_obj == user
      timeline(:own_favorites_list) << message
    end
  end

  on_gui_child_activated do |i_parent, i_child, by_toolkit|
    slug = i_child.slug
    if favorites_list_retrieve_queue_user.has_key?(slug)
      user = favorites_list_retrieve_queue_user[slug]
      if Service.primary.user_obj == user and slug != :own_favorites_list
        Plugin.call(:retrieve_favorites_list, Service.primary, user[:idname], [:own_favorites_list, slug], {count: [UserConfig[:favorites_list_retrieve_count], 200].min})
      else
        Plugin.call(:retrieve_favorites_list, Service.primary, user[:idname], slug, {count: [UserConfig[:favorites_list_retrieve_count], 200].min})
      end
      favorites_list_retrieve_queue_user.delete(slug)
    end
  end

end

