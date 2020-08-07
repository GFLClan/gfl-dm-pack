#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <gfldm>
#include <gfldm-chat>
#include <gfldm-clientprefs>

public Plugin myinfo = {
    name = "GFLDM Autosilencer",
    author = "Dreae",
    description = "Automatically attaches a silencer to valid weapons",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

bool silencer_enabled[MAXPLAYERS + 1] = {true, ...};
bool spawning[MAXPLAYERS + 1] = {false, ...};
Cookie enabled_cookie;

public void OnPluginStart() {
    DEFINE_VERSION("gfldm_autosilencer_version")
    for (int c = 1; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c)) {
            OnClientPutInServer(c);
        }
    }

    enabled_cookie = new Cookie("GFLDM_Autosilencer", "", CookieAccess_Protected);
    FIRE_CLIENT_COOKIES()

    RegConsoleCmd("sm_silencer", Cmd_Silencer, "Toggle autosilencer");
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn_Post, EventHookMode_Post);

    LoadTranslations("gfldm_autosilencer.phrases");
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GFLDM_IsValidClient(client, true)) {
        spawning[client] = true;
    }
}

public void Event_PlayerSpawn_Post(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GFLDM_IsValidClient(client, true)) {
        spawning[client] = false;
    }
}


public Action Cmd_Silencer(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    silencer_enabled[client] = !silencer_enabled[client];
    if (silencer_enabled[client]) {
        enabled_cookie.Set(client, "on");
        GFLDM_PrintToChat(client, "%t", "Autosilencer enabled");
    } else {
        enabled_cookie.Set(client, "off");
        GFLDM_PrintToChat(client, "%t", "Autosilencer disabled");
    }

    return Plugin_Handled;
}

public Action Hook_WeaponEquip(int client, int weapon) {
    if (GFLDM_IsValidClient(client) && IsValidEdict(client)) {
        char clsname[64];
        if (GetEdictClassname(weapon, clsname, sizeof(clsname))) {
            if ((StrEqual(clsname, "weapon_m4a1") || StrEqual(clsname, "weapon_usp")) && silencer_enabled[client]) {
                SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 1);
                SetEntProp(weapon, Prop_Send, "m_weaponMode", 1);
                GFLDM_PrintToChat(client, "%t", "Silenced", clsname);
            }
        }
    }
}

LOAD_COOKIE_BOOL(enabled_cookie, silencer_enabled, "on", true)
