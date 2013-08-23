theme = {}
theme.wallpaper  = os.getenv("HOME")..'/.config/awesome/walls/pantyvs.png'
theme.icon_theme = nil

-- {{{ Styles
theme.font          = "smoothansi 9"
theme.font_key      = "#FEFEFE"
theme.font_value    = "black"
--bg
theme.bg_normal     = "#F6D77DAA"
theme.bg_focus      = "#e60241AA"
theme.bg_urgent     = "b6fcb3"
theme.bg_minimize   = "0e2a69"
--fg
theme.fg_normal     = "#000000"
theme.fg_focus      = "#010101"
theme.fg_urgent     = "#000000"
theme.fg_minimize   = "#FEFEFE"
--border
theme.border_width  = "2"
theme.border_normal = "#010101"
theme.border_focus  = "#FEFEFE"
theme.border_marked = "green"
-- }}}
-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- }}}
-- {{{ Taglist
theme.taglist_squares_sel    = "/usr/share/awesome/themes/zenburn/taglist/squarefz.png"
theme.taglist_squares_unsel  = "/usr/share/awesome/themes/zenburn/taglist/squarez.png"
theme.taglist_squares_resize = "false"
-- }}}
-- {{{ Misc
theme.awesome_icon           = "/usr/share/awesome/themes/zenburn/awesome-icon.png"
theme.menu_submenu_icon      = "/usr/share/awesome/themes/default/submenu.png"
theme.tasklist_floating_icon = "/usr/share/awesome/themes/default/tasklist/floatingw.png"
-- }}}
-- {{{ Layout
theme.layout_fairh      = os.getenv("HOME")..'/.config/awesome/layouts/fairhw.png'
theme.layout_fairv      = os.getenv("HOME")..'/.config/awesome/layouts/fairvw.png'
theme.layout_floating   = os.getenv("HOME")..'/.config/awesome/layouts/floatingw.png'
theme.layout_magnifier  = os.getenv("HOME")..'/.config/awesome/layouts/magnifierw.png'
theme.layout_max        = os.getenv("HOME")..'/.config/awesome/layouts/maxw.png'
theme.layout_fullscreen = os.getenv("HOME")..'/.config/awesome/layouts/fullscreenw.png'
theme.layout_tilebottom = os.getenv("HOME")..'/.config/awesome/layouts/tilebottomw.png'
theme.layout_tileleft   = os.getenv("HOME")..'/.config/awesome/layouts/tileleftw.png'
theme.layout_tile       = os.getenv("HOME")..'/.config/awesome/layouts/tilew.png'
theme.layout_tiletop    = os.getenv("HOME")..'/.config/awesome/layouts/tiletopw.png'
-- }}}

return theme
