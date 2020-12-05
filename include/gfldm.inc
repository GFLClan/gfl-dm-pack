#if defined _gfldm_included
    #endinput
#endif
#define _gfldm_included
#define GFLDM_VERSION "1.5.2"

#include <cstrike>

#define DEFINE_VERSION(%1) \
    ConVar cvar_version = CreateConVar(%1, GFLDM_VERSION, "",  FCVAR_REPLICATED);\
    cvar_version.SetString(GFLDM_VERSION);

stock bool GFLDM_IsValidClient(int client, bots=false) {
    return (0 < client <= MaxClients) && IsClientInGame(client) && ((IsFakeClient(client) && bots) || !IsFakeClient(client));
}

stock int GFLDM_GetTeamCount(int team, bots=false) {
    int count = 0;
    for (int c = 1; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c, bots)) {
            if (GetClientTeam(c) == team) {
                count++;
            }
        }
    }

    return count;
}
