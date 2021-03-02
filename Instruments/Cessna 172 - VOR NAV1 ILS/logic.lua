---------------------------------------------
--           VOR / NAV1 with ILS           --
-- Modification of Jason Tatum's original  --
-- Brian McMullan 20180324                 -- 
-- Property for background off/on          --
-- Property for dimming overlay            --
-- some gauge initialization fixes         --
--                                         --
-- Additional modification by Håvard Fjær, --
-- adding internal tracking of OBS state   --
---------------------------------------------
---------------------------------------------
--   Properties                            --
---------------------------------------------
prop_BG = user_prop_add_boolean("Background Display", true, "Display background?")
prop_DO = user_prop_add_boolean("Dimming Overlay", false, "Enable dimming overlay?")

---------------------------------------------
--   Load and display images in Z-order    --
--   Loaded images selectable with prop    --
---------------------------------------------

-- Variables for tracking of OBS state
OBS_PRECISION_HIGH = 1
OBS_PRECISION_LOW = 10
obs_precision = OBS_PRECISION_LOW -- Starting precision

obs_deg_internal = -1 -- Internal state
obs_deg_reported = -1 -- State reported from simulator
obs_should_receive_sim_updates = true -- Controls if the sim may update our internal state (is set by encoder events and a timer)
obs_should_receive_sim_updates_again_after = 1000 -- Wait a second before listening to sim again.
obs_sim_update_timer = nil -- Tracks timer controlling when we start to listen to the sim again.

-- Debug state
DEBUG = true

img_to = img_add_fullscreen("OBSnavto.png")
img_fr = img_add_fullscreen("OBSnavfr.png")
img_navflag = img_add_fullscreen("OBSnavflag.png")
img_gs = img_add_fullscreen("OBSgsflagoff.png")
img_gsflag = img_add_fullscreen("OBSgsflag.png")
if user_prop_get(prop_BG) == false then
    img_add_fullscreen("VORILS.png")
else
    img_add_fullscreen("VORILSwBG.png")
end
img_horbar = img_add("OBSneedle.png", 0, -180, 512, 512)
img_verbar = img_add("OBSneedle.png", -150, 0, 512, 512)
rotate(img_verbar, -90)
img_compring = img_add_fullscreen("OBScard.png")
img_add_fullscreen("OBScover.png")
img_add("OBSknobshadow.png", 31, 395, 85, 85)

if user_prop_get(prop_DO) == true then
    img_add_fullscreen("dimoverlay.png")
end

---------------------------------------------
--   Init                                  --
---------------------------------------------
visible(img_to, false)
visible(img_fr, false)
visible(img_navflag, true)
visible(img_gsflag, true)

---------------------------------------------
--   Functions                             --
---------------------------------------------

function debug_print(message)
    if DEBUG then
        print(message)
    end
end

-- BUTTON, SWITCH AND DIAL FUNCTIONS --
function new_obs(obs)

    -- Disable updates from sim when interacting with encoder.
    obs_should_receive_sim_updates = false
    if obs_sim_update_timer ~= nil then
        debug_print("Stopping old timer")
        timer_stop(obs_sim_update_timer) -- stop timer before creating a new one
    end
    debug_print("Starting new timer")
    obs_sim_update_timer = timer_start(obs_should_receive_sim_updates_again_after, enable_updates_from_sim)

    if obs == 1 then
        -- xpl_command("sim/radios/obs1_down")
        -- fsx_event("VOR1_OBI_DEC")
        -- fs2020_event("VOR1_OBI_DEC")
        obs_deg_internal = obs_deg_internal - obs_precision
        debug_print("Dec " .. obs_precision);
    elseif obs == -1 then
        -- xpl_command("sim/radios/obs1_up")
        -- fsx_event("VOR1_OBI_INC")
        -- fs2020_event("VOR1_OBI_INC")
        obs_deg_internal = obs_deg_internal + obs_precision
        debug_print("Inc " .. obs_precision);
    end

    -- Handle northbound edge cases
    if obs_deg_internal >= 360 then
        obs_transferded_deg = obs_deg_internal % obs_precision
        debug_print("Went past 360 degrees, transfering to " .. obs_transferded_deg)
        obs_deg_internal = obs_transferded_deg
    end

    if obs_deg_internal < 0 then
        obs_transferded_deg = 360 + obs_deg_internal
        debug_print("Went down past 0 degrees, transfering to " .. obs_transferded_deg)
        obs_deg_internal = obs_transferded_deg
    end

    debug_print("OBS degrees: " .. obs_deg_internal)
    fs2020_event("VOR1_SET", obs_deg_internal)
    rotate(img_compring, obs_deg_internal * -1)

end

function change_obs_precision_pressed(obs_button)
    debug_print("OBS pressed")
    if obs_precision == OBS_PRECISION_LOW then
        obs_precision = OBS_PRECISION_HIGH
    else
        obs_precision = OBS_PRECISION_LOW
    end
end

function change_obs_precision_released(obs_button)
    debug_print("OBS released")
end

function enable_updates_from_sim()
    debug_print("Enabling updates from sim")
    obs_sim_update_timer = nil
    obs_should_receive_sim_updates = true
    if obs_deg_reported ~= obs_deg_internal then -- If there has been any external change while we have been waiting, ensure we are up-to-date
        debug_print("... and updating reported obs heading from sim")
        new_obsheading(obs_deg_reported)
    end
end

function new_obsheading(obs)
    obs_deg_reported = obs
    if obs_should_receive_sim_updates then
        obs_deg_internal = obs_deg_reported
        rotate(img_compring, obs_deg_internal * -1)
    end
end

function new_info(nav2sig, tofromnav, glideslopeflag)

    visible(img_navflag, nav2sig == 0)
    visible(img_to, tofromnav == 1)
    visible(img_fr, tofromnav == 2)
    visible(img_navflag, tofromnav == 0)
    visible(img_gsflag, glideslopeflag ~= 0)

end

function new_info_fsx(nav2sig, tofromnav, glideslopeflag)

    glideslopeflag = fif(glideslopeflag, 1, 0)

    new_info(nav2sig, tofromnav, glideslopeflag)

end

function new_dots(horizontal, vertical)

    -- Localizer
    horizontal = var_cap(horizontal, -5, 5)
    rotate(img_horbar, horizontal * -12)

    -- Glidescope
    vertical = var_cap(vertical, -4, 4)
    rotate(img_verbar, -90 + (vertical * 12))

end

function new_dots_fsx(vertical, horizontal)

    -- Localizer
    horizontal = 4 / 127 * horizontal
    horizontal = var_cap(horizontal, -4, 4)
    rotate(img_horbar, horizontal * -8)

    vertical = 4 / 119 * vertical

    -- Glidescope
    vertical = var_cap(vertical, -4, 4)
    rotate(img_verbar, -90 + (vertical * 5.4))

end

---------------------------------------------
--   Controls Add                          --
---------------------------------------------
dial_obs = dial_add("obsknob.png", 31, 395, 85, 85, 5, new_obs)
dial_click_rotate(dial_obs, 6)

hw_dial_add("OBS dial", "TYPE_1_DETENT_PER_PULSE", 1, 4, new_obs)
hw_button_add("OBS dial precision", change_obs_precision_pressed, change_obs_precision_released)

---------------------------------------------
--   Simulator Subscriptions               --
---------------------------------------------
fsx_variable_subscribe("NAV OBS:1", "Degrees", new_obsheading)
fsx_variable_subscribe("NAV HAS NAV:1", "Bool",
                       "NAV TOFROM:1", "Enum",
                       "NAV GS FLAG:1", "Bool", new_info_fsx)
                       
fsx_variable_subscribe("NAV GSI:1", "Number",
                       "NAV CDI:1", "Number", new_dots_fsx)
                       
fs2020_variable_subscribe("NAV OBS:1", "Degrees", new_obsheading)                       
fs2020_variable_subscribe("NAV HAS NAV:1", "Bool",
                          "NAV TOFROM:1", "Enum",
                          "NAV GS FLAG:1", "Bool", new_info_fsx)
                       
fs2020_variable_subscribe("NAV GSI:1", "Number",
                          "NAV CDI:1", "Number", new_dots_fsx)                       
                          
xpl_dataref_subscribe("sim/cockpit/radios/nav1_obs_degm", "FLOAT", new_obsheading)

xpl_dataref_subscribe("sim/cockpit2/radios/indicators/nav1_display_horizontal", "INT",
                      "sim/cockpit2/radios/indicators/nav1_flag_from_to_pilot", "INT", 
                      "sim/cockpit2/radios/indicators/hsi_flag_glideslope_pilot", "INT", new_info)

xpl_dataref_subscribe("sim/cockpit/radios/nav1_hdef_dot", "FLOAT",
                      "sim/cockpit/radios/nav1_vdef_dot", "FLOAT", new_dots)  
---------------------------------------------
-- END                                     --
---------------------------------------------                          
