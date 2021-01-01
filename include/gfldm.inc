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

#if defined _gfldm_included
    #endinput
#endif
#define _gfldm_included
#define GFLDM_VERSION "2.1.1"

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

stock any GFLDM_GetNativeHandle(int param) {
    Handle hndl = GetNativeCell(param);
    if (hndl == INVALID_HANDLE) {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid handle: %d", hndl);
    }

    return hndl;
}