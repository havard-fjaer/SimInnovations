---------------------------------------------
--           VOR / NAV1 with ILS           --
-- Modification of Jason Tatum's original  --
-- Brian McMullan 20180324                 -- 
-- Property for background off/on          --
-- Property for dimming overlay            --
-- some gauge initialization fixes         --
---------------------------------------------

---------------------------------------------
--   Properties                            --
---------------------------------------------
prop_BG = user_prop_add_boolean("Background Display",true,"Display background?")
prop_DO = user_prop_add_boolean("Dimming Overlay",false,"Enable dimming overlay?")

---------------------------------------------
--   Load and display images in Z-order    --
--   Loaded images selectable with prop    --
---------------------------------------------

obs_deg = 0


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
img_horbar = img_add("OBSneedle.png",0,-180,512,512)
img_verbar = img_add("OBSneedle.png",-150,0,512,512)
rotate(img_verbar, -90)
img_compring = img_add_fullscreen("OBScard.png")
img_add_fullscreen("OBScover.png")
img_add("OBSknobshadow.png",31,395,85,85)

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

-- BUTTON, SWITCH AND DIAL FUNCTIONS --
function new_obs(obs)

    if obs == 1 then
        xpl_command("sim/radios/obs1_down")
        fsx_event("VOR1_OBI_DEC")
        --fs2020_event("VOR1_OBI_DEC")
        obs_deg = obs_deg -5
        fs2020_event("VOR1_SET", obs_deg)
        print("dec");
    elseif obs == -1 then
        xpl_command("sim/radios/obs1_up")
        fsx_event("VOR1_OBI_INC")
        -- fs2020_event("VOR1_OBI_INC")
        
        -- NAV_OBS_1
        obs_deg = obs_deg +5
        fs2020_event("VOR1_SET", obs_deg)
        print("inc");
    end

end

function new_obsheading(obs)
    --obs_deg = obs
    rotate(img_compring, obs * -1)
    
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