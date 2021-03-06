----------------------------------------------------------------------------
--- Theme library.
--
-- @author Damien Leone &lt;damien.leone@gmail.com&gt;
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Damien Leone, Julien Danjou
-- @release @AWESOME_VERSION@
-- @module beautiful
----------------------------------------------------------------------------

-- Grab environment
local os = os
local print = print
local pcall = pcall
local pairs = pairs
local type = type
local dofile = dofile
local setmetatable = setmetatable
local util = require("awful.util")
local lgi = require("lgi")
local cairo = lgi.cairo
local Pango = lgi.Pango
local PangoCairo = lgi.PangoCairo
local capi =
{
    screen = screen,
    awesome = awesome
}
local gears_debug = require("gears.debug")

local xresources = require("beautiful.xresources")

local beautiful = { xresources = xresources, mt = {} }

-- Local data
local theme = {}
local descs = setmetatable({}, { __mode = 'k' })
local fonts = setmetatable({}, { __mode = 'v' })
local active_font

--- Load a font from a string or a font description.
--
-- @see https://developer.gnome.org/pango/stable/pango-Fonts.html#pango-font-description-from-string
-- @tparam string|lgi.Pango.FontDescription name Font, which can be a
--   string or a lgi.Pango.FontDescription.
-- @treturn table A table with `name`, `description` and `height`.
local function load_font(name)
    name = name or active_font
    if name and type(name) ~= "string" then
        if descs[name] then
            name = descs[name]
        else
            name = name:to_string()
        end
    end
    if fonts[name] then
        return fonts[name]
    end

    -- Load new font
    local desc = Pango.FontDescription.from_string(name)
    local ctx = PangoCairo.font_map_get_default():create_context()
    ctx:set_resolution(beautiful.xresources.get_dpi())

    -- Apply default values from the context (e.g. a default font size)
    desc:merge(ctx:get_font_description(), false)

    -- Calculate font height.
    local metrics = ctx:get_metrics(desc, nil)
    local height = math.ceil((metrics:get_ascent() + metrics:get_descent()) / Pango.SCALE)

    local font = { name = name, description = desc, height = height }
    fonts[name] = font
    descs[desc] = name
    return font
end

--- Set an active font
--
-- @param name The font
local function set_font(name)
    active_font = load_font(name).name
end

--- Get a font description.
--
-- See https://developer.gnome.org/pango/stable/pango-Fonts.html#PangoFontDescription.
-- @tparam string|lgi.Pango.FontDescription name The name of the font.
-- @treturn lgi.Pango.FontDescription
function beautiful.get_font(name)
    return load_font(name).description
end

--- Get a new font with merged attributes, based on another one.
--
-- See https://developer.gnome.org/pango/stable/pango-Fonts.html#pango-font-description-from-string.
-- @tparam string|Pango.FontDescription name The base font.
-- @tparam string merge Attributes that should be merged, e.g. "bold".
-- @treturn lgi.Pango.FontDescription
function beautiful.get_merged_font(name, merge)
    local font = beautiful.get_font(name)
    local merge = Pango.FontDescription.from_string(merge)
    local merged = font:copy_static()
    merged:merge(merge, true)
    return beautiful.get_font(merged:to_string())
end

--- Get the height of a font.
--
-- @param name Name of the font
function beautiful.get_font_height(name)
    return load_font(name).height
end

--- Init function, should be runned at the beginning of configuration file.
-- @tparam string|table config The theme to load. It can be either the path to
--   the theme file (returning a table) or directly the table
--   containing all the theme values.
function beautiful.init(config)
    if config then
        local success
        local homedir = os.getenv("HOME")

        -- If config is the path to the theme file,
        -- run this file,
        -- else if it is the theme table, save it
        if type(config) == 'string' then
            -- Expand the '~' $HOME shortcut
            config = config:gsub("^~/", homedir .. "/")
            success, theme = xpcall(function() return dofile(config) end,
                                    debug.traceback)
        elseif type(config) == 'table' then
            success = true
            theme = config
        end

        if not success then
            return gears_debug.print_error("beautiful: error loading theme file " .. theme)
        elseif theme then
            -- expand '~'
            if homedir then
                for k, v in pairs(theme) do
                    if type(v) == "string" then theme[k] = v:gsub("^~/", homedir .. "/") end
                end
            end

            if theme.font then set_font(theme.font) end
        else
            return gears_debug.print_error("beautiful: error loading theme file " .. config)
        end
    else
        return gears_debug.print_error("beautiful: error loading theme: no theme specified")
    end
end

--- Get the current theme.
--
-- @treturn table The current theme table.
function beautiful.get()
    return theme
end

function beautiful.mt:__index(k)
    return theme[k]
end

-- Set the default font
set_font("sans 8")

return setmetatable(beautiful, beautiful.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
