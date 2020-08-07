#pragma semicolon 1

#include <sourcemod>
#include <gfldm>
#include <gfldm-chat>
#include <gfldm-stats>
#include <gfldm-clientprefs>

public Plugin myinfo = {
    name = "GFLDM Hitboxes",
    author = "Dreae",
    description = "Shows player hitbox stats",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

ConVar cvar_hitbox_show_on_spawn;
bool hitbox_show_on_spawn;
bool hitboxes_enabled[MAXPLAYERS + 1] = {false, ...};
float last_update[MAXPLAYERS + 1] = {0.0, ...};
Cookie enabled_cookie;

public void OnPluginStart() {
    DEFINE_VERSION("gfldm_hitboxes_version")
    cvar_hitbox_show_on_spawn = CreateConVar("gfldm_hitboxme_on_spawn", "1", "Show hitbox stats on spawn");
    cvar_hitbox_show_on_spawn.AddChangeHook(CvarChanged);
    enabled_cookie = new Cookie("gfldm-showhitboxes", "", CookieAccess_Protected);
    CreateTimer(5.0, Timer_RefreshHitboxes, 0, TIMER_REPEAT);
    FIRE_CLIENT_COOKIES()

    HookEvent("player_spawn", Hook_PlayerSpawn);

    RegConsoleCmd("sm_hitboxme", Cmd_HitboxMe);
    LoadTranslations("gfldm_hitboxes.phrases");
}

LOAD_COOKIE_BOOL(enabled_cookie, hitboxes_enabled, "off", false)

public void OnConfigsExecuted() {
    hitbox_show_on_spawn = cvar_hitbox_show_on_spawn.BoolValue;
}

public void CvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue) {
    hitbox_show_on_spawn = cvar_hitbox_show_on_spawn.BoolValue;
}

public Action Timer_RefreshHitboxes(Handle timer, any data) {
    for (int c = 1; c <= MaxClients; c++) {
        float game_time = GetGameTime();
        if (GFLDM_IsValidClient(c) && hitboxes_enabled[c] && game_time - last_update[c] > 2.5) {
            GFLDM_WithPlayerStats(c, Callback_PlayerStats);
        }
    }
}

public void Hook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GFLDM_IsValidClient(client) && hitbox_show_on_spawn) {
        GFLDM_WithPlayerStats(client, Callback_PlayerStats);
    }
}

public Action Cmd_HitboxMe(int client, int args) {
    GFLDM_WithPlayerStats(client, Callback_PlayerStats);
    hitboxes_enabled[client] = !hitboxes_enabled[client];
    if (hitboxes_enabled[client]) {
        enabled_cookie.Set(client, "on");
    } else {
        enabled_cookie.Set(client, "off");
    }
    return Plugin_Handled;
}

public void GFLDM_OnStatsUpdate(int client, int stat_class, PlayerStats stats) {
    if (stat_class & STATCLASS_HITBOXES != 0) {
        if (hitboxes_enabled[client]) {
            Callback_PlayerStats(client, stats);
        }
    }
}

public void Callback_PlayerStats(int client, PlayerStats stats) {
    char body[128];
    float hits = float(stats.hits);
    SetGlobalTransTarget(client);

    char head[24];
    Format(head, sizeof(head), "%t: %.2f", "Head", (float(stats.hitboxes.head) / hits) * 100.0);
    char chest[24];
    Format(chest, sizeof(chest), "%t: %.2f", "Chest", (float(stats.hitboxes.chest) / hits) * 100.0);
    char stomach[24];
    Format(stomach, sizeof(stomach), "%t: %.2f", "Stomach", (float(stats.hitboxes.stomach) / hits) * 100.0);
    char left_arm[24];
    Format(left_arm, sizeof(left_arm), "%t: %.2f", "Left Arm", (float(stats.hitboxes.left_arm) / hits) * 100.0);
    char right_arm[24];
    Format(right_arm, sizeof(right_arm), "%t: %.2f", "Right Arm", (float(stats.hitboxes.right_arm) / hits) * 100.0);
    char left_leg[24];
    Format(left_leg, sizeof(left_leg), "%t: %.2f", "Left Leg", (float(stats.hitboxes.left_leg) / hits) * 100.0);
    char right_leg[24];
    Format(right_leg, sizeof(right_leg), "%t: %.2f", "Right Leg", (float(stats.hitboxes.right_leg) / hits) * 100.0);

    Format(body, sizeof(body), "!hitboxme\n%s\n%s\n%s\n%s\n%s\n%s\n%s",
        head,
        chest,
        stomach,
        left_arm,
        right_arm,
        left_leg,
        right_leg
    );
    Handle msg = StartMessageOne("KeyHintText", client);
    if (msg != null) {
        BfWriteByte(msg, 1);
        BfWriteString(msg, body);

        EndMessage();
    }

    last_update[client] = GetGameTime();
}