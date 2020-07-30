#pragma semicolon 1

#include <sourcemod>
#include <gfldm>

public Plugin myinfo = {
    name = "GFL DM TeamBalance",
    author = "Dreae",
    description = "Balances teams",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

public void OnPluginLoad() {
    HookEvent("player_death", OnPlayerDeath);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (GFLDM_IsValidClient(victim)) {
        int count_t = GFLDM_GetTeamCount(CS_TEAM_T);
        int count_ct = GFLDM_GetTeamCount(CS_TEAM_CT);

        if (GetClientTeam(victim) == CS_TEAM_T && count_t - count_ct > 1) {
            ChangeClientTeam(victim, CS_TEAM_CT);
        } else if (GetClientTeam(victim) == CS_TEAM_T && count_ct - count_t > 1) {
            ChangeClientTeam(victim, CS_TEAM_T);
        }
    }
}
