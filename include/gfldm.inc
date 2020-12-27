#if defined _gfldm_included
    #endinput
#endif
#define _gfldm_included
#define GFLDM_VERSION "1.6.0"

#include <cstrike>

stock void GFLDM_DefineVersion(const char[] version_cvar) {
    ConVar cvar_version = FindConVar(version_cvar);
    if (cvar_version == null) {
        CreateConVar(version_cvar, GFLDM_VERSION, "", FCVAR_REPLICATED);
    } else {
        cvar_version.SetString(GFLDM_VERSION, true, false);
    }
}

stock bool GFLDM_IsValidClient(int client, bool bots=false) {
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

stock void GFLDM_RequireLibrary(const char[] library) {
    if (!LibraryExists(library)) {
        SetFailState("Missing GFLDM component: %s", library);
    }
}

stock void GFLDM_EmitSound(int client, const char[] sound_file, float volume=1.0) {
    if (GFLDM_IsValidClient(client)) {
        EmitSoundToClient(client, sound_file, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, volume);
    }
}