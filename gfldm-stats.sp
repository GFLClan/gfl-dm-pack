#pragma semicolon 1

#include <sourcemod>
#include <gfldm>
#include <gfldm-stats>

public Plugin myinfo = {
    name = "GFLDM Stats",
    author = "Dreae",
    description = "Tracks player session statistics",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

PlayerStats playerStats[MAXPLAYERS + 1];
GlobalForward fwd_statsChange;

public void OnPluginStart() {
    DEFINE_VERSION("gfldm_stats_version")
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("player_hurt", EventPlayerHurt);
    HookEvent("weapon_fire", EventWeaponFire);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] err, int errmax) {
    fwd_statsChange = new GlobalForward("GFLDM_OnStatsUpdate", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
    RegPluginLibrary("gfldm-stats");
}

public void EventPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!GFLDM_IsValidClient(victim, true) || !GFLDM_IsValidClient(attacker, true) || victim == attacker) {
        return;
    }

    playerStats[victim].deaths++;
    playerStats[victim].current_streak = 0;
    FireForward(victim, STATCLASS_DEATHS | STATCLASS_KDR);

    int stat_class = STATCLASS_KILLS | STATCLASS_KDR | STATCLASS_STREAK;
    playerStats[attacker].kills++;
    playerStats[attacker].current_streak++;
    if (playerStats[attacker].current_streak > playerStats[attacker].highest_streak) {
        playerStats[attacker].highest_streak = playerStats[attacker].current_streak;
        stat_class = stat_class | STATCLASS_HIGHEST_STREAK;
    }

    if (event.GetBool("headshot")) {
        playerStats[attacker].headshots++;
        stat_class = stat_class | STATCLASS_HEADSHOTS;
    }
    
    FireForward(attacker, stat_class);
}

public void EventPlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!GFLDM_IsValidClient(victim, true) || !GFLDM_IsValidClient(attacker, true) || victim == attacker) {
        return;
    }

    int hitgroup = event.GetInt("hitgroup");
    if (hitgroup == 0) {
        return;
    }

    if (hitgroup == 8) {
        hitgroup = 1;
    }

    playerStats[attacker].hits++;
    switch (hitgroup) {
        case 1:
            playerStats[attacker].hitboxes.head++;
        case 2:
            playerStats[attacker].hitboxes.chest++;
        case 3:
            playerStats[attacker].hitboxes.stomach++;
        case 4:
            playerStats[attacker].hitboxes.left_arm++;
        case 5:
            playerStats[attacker].hitboxes.right_arm++;
        case 6:
            playerStats[attacker].hitboxes.left_leg++;
        case 7:
            playerStats[attacker].hitboxes.right_leg++;
    }

    FireForward(attacker, STATCLASS_ACCURACY | STATCLASS_HITBOXES);
}

public void EventWeaponFire(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!GFLDM_IsValidClient(client, true)) {
        return;
    }

    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));
    if (StrContains(weapon, "knife") != -1 || 
        StrEqual(weapon, "weapon_bayonet") || 
        StrEqual(weapon, "weapon_melee") || 
        StrEqual(weapon, "weapon_axe") || 
        StrEqual(weapon, "weapon_hammer") || 
        StrEqual(weapon, "weapon_spanner") || 
        StrEqual(weapon, "weapon_fists") || 
        StrEqual(weapon, "weapon_hegrenade") || 
        StrEqual(weapon, "weapon_flashbang") || 
        StrEqual(weapon, "weapon_smokegrenade") || 
        StrEqual(weapon, "weapon_inferno") || 
        StrEqual(weapon, "weapon_molotov") || 
        StrEqual(weapon, "weapon_incgrenade") ||
        StrContains(weapon, "decoy") != -1 ||
        StrEqual(weapon, "weapon_firebomb") ||
        StrEqual(weapon, "weapon_diversion") ||
        StrContains(weapon, "breachcharge") != -1) {
        return;
    }

    playerStats[client].shots++;
    FireForward(client, STATCLASS_ACCURACY);
}

public void GFLDM_OnNoscope(int attacker, int victim, bool headshot, float distance) {
    playerStats[attacker].noscopes++;
    FireForward(attacker, STATCLASS_NOSCOPES);
}

public void OnClientDisconnect(int client) {
    PlayerStats zero;
    playerStats[client] = zero;
    FireForward(client, STATCLASS_DISCONNECT);
}

void FireForward(int client, int stat_class) {
    PlayerStats stats;
    stats = playerStats[client];

    Call_StartForward(fwd_statsChange);
    Call_PushCell(client);
    Call_PushCell(stat_class);
    Call_PushArray(stats, sizeof(stats));
    Call_Finish();
}