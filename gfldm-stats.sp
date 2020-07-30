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

public void OnPluginStart() {
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("player_hurt", EventPlayerHurt);
    HookEvent("weapon_fire", EventWeaponFire);
}

public void EventPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!GFLDM_IsValidClient(victim, true) || !GFLDM_IsValidClient(attacker) || victim == attacker) {
        return;
    }

    playerStats[victim].deaths++;
    playerStats[attacker].kills++;
    
    if (event.GetBool("headshot")) {
        playerStats[attacker].headshots++;
    }
}

public void EventPlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!GFLDM_IsValidClient(victim, true) || !GFLDM_IsValidClient(attacker) || victim == attacker) {
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
}

public void EventWeaponFire(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!GFLDM_IsValidClient(client)) {
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
}