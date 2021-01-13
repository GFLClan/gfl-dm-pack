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
#include <gfldm-chat>

public Plugin myinfo = {
    name = "GFLDM TeamBalance",
    author = "Dreae",
    description = "Balances teams",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

ConVar cvar_max_diff;
int max_diff = 2;

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_teambalance_version");
    HookEvent("player_death", OnPlayerDeath);
    cvar_max_diff = CreateConVar("gfldm_teambalance_max_diff", "2", "Maximum team difference allowed before players are balanced");
    cvar_max_diff.AddChangeHook(Cvar_ConfigChanged);

    LoadTranslations("gfldm_teambalance.phrases");
    AutoExecConfig();
}

public void OnConfigsExecuted() {
    max_diff = cvar_max_diff.IntValue;
}

public void Cvar_ConfigChanged(ConVar cvar, const char[] oldValue, const char[] newValue) {
    OnConfigsExecuted();
}

public void BalancePlayer(any data) {
    int victim = data;
    if (GFLDM_IsValidClient(victim)) {
        int count_t = GFLDM_GetTeamCount(CS_TEAM_T);
        int count_ct = GFLDM_GetTeamCount(CS_TEAM_CT);

        if (GetClientTeam(victim) == CS_TEAM_T && count_t - count_ct > max_diff) {
            CS_SwitchTeam(victim, CS_TEAM_CT);
            GFLDM_PrintToChat(victim, "%t", "Switched CT");
        } else if (GetClientTeam(victim) == CS_TEAM_CT && count_ct - count_t > max_diff) {
            CS_SwitchTeam(victim, CS_TEAM_T);
            GFLDM_PrintToChat(victim, "%t", "Switched T");
        }
    }
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (GFLDM_IsValidClient(victim)) {
        RequestFrame(BalancePlayer, victim);
    }
}
