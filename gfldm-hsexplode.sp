#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gfldm>
#include <gfldm-chat>
#include <gfldm-clientprefs>
#include <gfldm-anim>

public Plugin myinfo = {
    name = "GFLDM Headshot Explode",
    author = "Dreae",
    description = "Headshots explode",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

bool explosions_enabled[MAXPLAYERS + 1] = {true, ...};
Cookie enabled_cookie;

int admin_flags = 0;
ConVar cvar_admin_flag;

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_hsexplode_version");
    
    cvar_admin_flag = CreateConVar("gfldm_hsexplode_flag", "t", "Admin flags required to enable HS explosions");
    cvar_admin_flag.AddChangeHook(cvar_Changed);

    RegConsoleCmd("sm_hsexplode", Cmd_HSExplode, "Toggle headshot explosions");

    enabled_cookie = new Cookie("GFLDM_HSExplode", "", CookieAccess_Protected);
    FIRE_CLIENT_COOKIES()

    HookEvent("player_death", Event_PlayerDeath);
    AutoExecConfig();
    LoadTranslations("gfldm_hsexplode.phrases");
}

public Action Cmd_HSExplode(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    explosions_enabled[client] = !explosions_enabled[client];
    if (explosions_enabled[client]) {
        enabled_cookie.Set(client, "on");
        GFLDM_PrintToChat(client, "%t", "HS explosions enabled");
    } else {
        enabled_cookie.Set(client, "off");
        GFLDM_PrintToChat(client, "%t", "HS explosions disabled");
    }

    return Plugin_Handled;
}

public void cvar_Changed(ConVar cvar, const char[] oldValue, const char[] newValue) {
    OnConfigsExecuted();
}

public void OnConfigsExecuted() {
    char flagString[64];
    cvar_admin_flag.GetString(flagString, sizeof(flagString));
    admin_flags = ReadFlagString(flagString);
}

LOAD_COOKIE_BOOL(enabled_cookie, explosions_enabled, "on", true)

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (!GFLDM_IsValidClient(victim, true) || !GFLDM_IsValidClient(attacker) || victim == attacker) {
        return;
    }

    if (admin_flags != 0) {
        AdminId admin = GetUserAdmin(attacker);
        if (admin == INVALID_ADMIN_ID || !CheckAccess(admin, "", admin_flags, true)) {
            return;
        }
    }

    if (event.GetBool("headshot") && explosions_enabled[attacker]) {
        float origin[3];
        GetClientAbsOrigin(victim, origin);

        GFLDMAnimation anim = new GFLDMAnimation();
        anim.AddExplosion(ExplosionNormal, origin);
        anim.Play();
    }
}