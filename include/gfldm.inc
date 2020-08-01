#if defined _gfldm_included
    #endinput
#endif
#define _gfldm_included
#define GFLDM_VERSION "1.3.0"

#include <cstrike>

stock bool GFLDM_IsValidClient(int client, bots=false) {
    return (1 <= client <= MaxClients) && IsClientInGame(client) && ((IsFakeClient(client) && bots) || !IsFakeClient(client));
}

stock int GFLDM_GetTeamCount(int team) {
    int count = 0;
    for (int c = 1; c < MaxClients; c++) {
        if (GFLDM_IsValidClient(c, true)) {
            if (GetClientTeam(c) == team) {
                count++;
            }
        }
    }

    return count;
}
