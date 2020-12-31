// Copyright (C) 2020 dreae
// 
// This file is part of gfl-dm-pack.
// 
// gfl-dm-pack is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// gfl-dm-pack is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with gfl-dm-pack.  If not, see <http://www.gnu.org/licenses/>.

#pragma semicolon 1

#include <sourcemod>
#include <gfldm>
#include <gfldm-stats>
#include <gfldm-chat>

public Plugin myinfo = {
    name = "GFLDM Stats",
    author = "Dreae",
    description = "Tracks player session statistics",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

PlayerStats playerStats[MAXPLAYERS + 1];
bool pendingFrameCallback[MAXPLAYERS + 1];
int pendingFrameClass[MAXPLAYERS + 1];
int victimsThisFrame[MAXPLAYERS + 1][6];
int victimCount[MAXPLAYERS + 1];
Shot playerShots[MAXPLAYERS + 1][6];
Shot shotThisFrame[MAXPLAYERS + 1];

GlobalForward fwd_statsChange;
ConVar cvar_allow_reset;
bool csgo = false;

float current_frame_time;

// OnGameFrame is called at the start of simulating the current tick
public void OnGameFrame() {
    current_frame_time = GetTickedTime();
}

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_stats_version");
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("player_hurt", EventPlayerHurt);
    HookEvent("weapon_fire", EventWeaponFire);

    cvar_allow_reset = CreateConVar("gfldm_stats_allow_reset", "1", "Allow players to reset their stats");
    RegConsoleCmd("sm_rs", Cmd_Reset, "Reset your stats for this session");

    LoadTranslations("gfldm_stats.phrases");

    char mod[16];
    GetGameFolderName(mod, sizeof(mod));
    csgo = StrEqual(mod, "csgo", false);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] err, int errmax) {
    fwd_statsChange = new GlobalForward("GFLDM_OnStatsUpdate", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell);
    CreateNative("GFLDM_WithPlayerStats", Native_WithPlayerStats);
    RegPluginLibrary("gfldm-stats");
}

public Action Cmd_Reset(int client, int args) {
    if (cvar_allow_reset.BoolValue && GFLDM_IsValidClient(client)) {
        PlayerStats zero;
        playerStats[client] = zero;
        
        SetEntProp(client, Prop_Data, "m_iFrags", 0);
        SetEntProp(client, Prop_Data, "m_iDeaths", 0);
        if (csgo) {
            CS_SetClientContributionScore(client, 0);
            CS_SetClientAssists(client, 0);
        }

        ScheduleFrameCallback(client, STATCLASS_RESET);
        GFLDM_PrintToChat(client, "%t", "Stats Reset");
    }

    return Plugin_Handled;
}

public int Native_WithPlayerStats(Handle plugin, int numParas) {
    int client = GetNativeCell(1);
    if (!GFLDM_IsValidClient(client, true)) {
        return false;
    }

    StatFunction func = GetNativeCell(2);
    Call_StartFunction(plugin, func);
    Call_PushCell(client);
    Call_PushArray(playerStats[client], sizeof(playerStats[]));
    Call_Finish();

    return 0;
}

public void EventPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!GFLDM_IsValidClient(victim, true) || !GFLDM_IsValidClient(attacker, true)) {
        return;
    }
    playerStats[victim].deaths++;
    playerStats[victim].current_streak = 0;
    ScheduleFrameCallback(victim, STATCLASS_DEATHS | STATCLASS_KDR);

    // Suicide, don't update attacker stats
    if (victim == attacker) {
        return;
    }

    int stat_class = STATCLASS_KILLS | STATCLASS_KDR | STATCLASS_STREAK;
    playerStats[attacker].kills++;
    playerStats[attacker].current_streak++;
    
    if (playerStats[attacker].last_kill == current_frame_time) {
        stat_class = stat_class | STATCLASS_COLLATERAL;
    }

    if (playerStats[attacker].current_streak > playerStats[attacker].highest_streak) {
        playerStats[attacker].highest_streak++;
        stat_class = stat_class | STATCLASS_HIGHEST_STREAK;
    }

    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));
    strcopy(shotThisFrame[attacker].weapon, 32, weapon);
    shotThisFrame[attacker].hit = true;
    shotThisFrame[attacker].kill = true;
    shotThisFrame[attacker].time = current_frame_time;
    
    if (event.GetBool("headshot")) {
        playerStats[attacker].headshots++;
        stat_class = stat_class | STATCLASS_HEADSHOTS;
        shotThisFrame[attacker].headshot = true;
    }

    if (StrContains(weapon, "knife") != -1 || 
        StrEqual(weapon, "weapon_bayonet") || 
        StrEqual(weapon, "weapon_melee") || 
        StrEqual(weapon, "weapon_axe") || 
        StrEqual(weapon, "weapon_hammer") || 
        StrEqual(weapon, "weapon_spanner") || 
        StrEqual(weapon, "weapon_fists")) {
        playerStats[attacker].knifes++;
        stat_class = stat_class | STATCLASS_KNIFES;
    }

    playerStats[attacker].last_kill = current_frame_time;
    RecordVictim(attacker, victim);
    ScheduleFrameCallback(attacker, stat_class);
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

    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));
    strcopy(shotThisFrame[attacker].weapon, 32, weapon);
    shotThisFrame[attacker].hit = true;
    shotThisFrame[attacker].time = GetGameTime();

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

    ScheduleFrameCallback(attacker, STATCLASS_ACCURACY | STATCLASS_HITBOXES);
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

    strcopy(shotThisFrame[client].weapon, 32, weapon);
    shotThisFrame[client].time = current_frame_time;

    playerStats[client].shots++;
    playerStats[client].last_shot = current_frame_time;
    ScheduleFrameCallback(client, STATCLASS_ACCURACY);
}

public void GFLDM_OnNoscope(int attacker, int victim, bool headshot, float distance) {
    playerStats[attacker].noscopes++;
    ScheduleFrameCallback(attacker, STATCLASS_NOSCOPES);
}

void RecordVictim(int client, int victim) {
    if (victimCount[client] < 6) {
        victimsThisFrame[client][victimCount[client]] = victim;
        victimCount[client]++;
    }
}

public void OnClientDisconnect(int client) {
    PlayerStats zero;
    playerStats[client] = zero;
    for (int c = 0; c < 6; c++) {
        Shot zeroShot;
        playerShots[client][c] = zeroShot;
    }
    ScheduleFrameCallback(client, STATCLASS_DISCONNECT);
}

void ScheduleFrameCallback(int client, int stat_class) {
    if (!pendingFrameCallback[client]) {
        RequestFrame(Frame_FireForward, client);
        pendingFrameCallback[client] = true;
    }
    pendingFrameClass[client] = pendingFrameClass[client] | stat_class;
}

void Frame_FireForward(any data) {
    int client = data;
    
    ResolveFrameShot(client);
    FireForward(client, pendingFrameClass[client], victimsThisFrame[client], victimCount[client]);

    ClearFrameData(client);
}

void ResolveFrameShot(int client) {
    if (pendingFrameClass[client] & STATCLASS_ACCURACY == 0 || pendingFrameClass[client] == STATCLASS_DISCONNECT) {
        return;
    }

    if (playerStats[client].shots == 1) {
        if (StrEqual(shotThisFrame[client].weapon, "deagle") && shotThisFrame[client].headshot && shotThisFrame[client].kill) {
            pendingFrameClass[client] = pendingFrameClass[client] | STATCLASS_ONE_DEAG;
            playerStats[client].one_deags++;
        } else if (StrEqual(shotThisFrame[client].weapon, "awp") && shotThisFrame[client].kill) {
            pendingFrameClass[client] = pendingFrameClass[client] | STATCLASS_AWP_OSOK;
        } else if (StrEqual(shotThisFrame[client].weapon, "scout") && shotThisFrame[client].kill) {
            pendingFrameClass[client] = pendingFrameClass[client] | STATCLASS_SCOUT_OSOK;
        }
    } else {
        int shot_idx = (playerStats[client].shots - 1) % 6;
        if (StrEqual(shotThisFrame[client].weapon, "deagle") && shotThisFrame[client].headshot && shotThisFrame[client].kill) {
            if (playerShots[client][shot_idx].kill || ((current_frame_time - playerShots[client][shot_idx].time) > 3.0)) {
                pendingFrameClass[client] = pendingFrameClass[client] | STATCLASS_ONE_DEAG;
            }
        } else if (StrEqual(shotThisFrame[client].weapon, "awp") && shotThisFrame[client].kill) {
            if (playerShots[client][shot_idx].kill || (current_frame_time - playerShots[client][shot_idx].time) > 6.0) {
                pendingFrameClass[client] = pendingFrameClass[client] | STATCLASS_AWP_OSOK;
            }
        } else if (StrEqual(shotThisFrame[client].weapon, "scout") && shotThisFrame[client].kill) {
            if (playerShots[client][shot_idx].kill || (current_frame_time - playerShots[client][shot_idx].time) > 6.0) {
                pendingFrameClass[client] = pendingFrameClass[client] | STATCLASS_SCOUT_OSOK;
            }
        }
    }

    playerShots[client][playerStats[client].shots % 6] = shotThisFrame[client];
}

void ClearFrameData(int client) {
    pendingFrameCallback[client] = false;
    pendingFrameClass[client] = 0;
    victimsThisFrame[client] = {0, 0, 0, 0, 0, 0};
    victimCount[client] = 0;
    Shot zero;
    shotThisFrame[client] = zero;
}

void FireForward(int client, int stat_class, int[] victims, int clientVictimCount) {
    PlayerStats stats;
    stats = playerStats[client];

    Call_StartForward(fwd_statsChange);
    Call_PushCell(client);
    Call_PushCell(stat_class);
    Call_PushArray(stats, sizeof(stats));
    Call_PushArray(victims, clientVictimCount);
    Call_PushCell(clientVictimCount);
    Call_Finish();
}