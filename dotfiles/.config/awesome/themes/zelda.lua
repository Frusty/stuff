theme = {}
theme.wallpaper  = os.getenv("HOME")..'/.config/awesome/walls/zelda_dangerous.png'
theme.icon_theme = nil


-- {{{ Stylesz
theme.font          = "smoothansi 9"
theme.font_key      = "white"
theme.font_value    = "black"
--bg
--theme.bg_normal     = "#EA9E22AA"
theme.bg_normal     = "#88D800AA"
theme.bg_focus      = "#000000AA"
theme.bg_urgent     = "red"
theme.bg_minimize   = "#444444"
--fg
theme.fg_normal     = "white"
theme.fg_focus      = "white"
theme.fg_urgent     = "red"
theme.fg_minimize   = "white"
--border
theme.border_width  = "2"
theme.border_normal = "#561d00"
theme.border_focus  = "#FFFFFF66"
theme.border_marked = "#8B000066"
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
