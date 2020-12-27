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
#include <sdkhooks>
#include <gfldm>
#include <gfldm-chat>

public Plugin myinfo = {
    name = "GFLDM Core",
    author = "Dreae",
    description = "Basic DM QoL improvements",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

ConVar cvar_remove_physics_ents;
ConVar cvar_clean_up_weapons;
ConVar cvar_autorestart_map;
ConVar cvar_mapchange_delay;
bool clean_up_weapons = false;
int map_reload_time = 0;
int map_reload_interval = 0;
int map_change_delay = 0;

public void OnPluginStart() {
    cvar_remove_physics_ents = CreateConVar("gfldm_remove_physics_ents", "1", "Remove CPhysicsPropMultiplayer");
    cvar_clean_up_weapons = CreateConVar("gfldm_clean_up_weapons", "1", "Remove dropped weapons");
    cvar_clean_up_weapons.AddChangeHook(CvarChanged);
    cvar_autorestart_map = CreateConVar("gfldm_restart_map_interval", "0", "Restart the map every x seconds");
    cvar_autorestart_map.AddChangeHook(CvarChanged);
    cvar_mapchange_delay = CreateConVar("gfldm_restart_map_delay", "5", "Wait x seconds before reloading the map");
    cvar_mapchange_delay.AddChangeHook(CvarChanged);

    GFLDM_DefineVersion("gfldm_version");

    HookEvent("round_start", Event_RoundStart);
    RegConsoleCmd("sm_usermessage", ConCmd_Message);

    for (int c = 1; c <= MaxClients; c++) {
        if (IsClientInGame(c)) {
            OnClientPutInServer(c);
        }
    }

    AutoExecConfig();
    LoadTranslations("gfldm.phrases.txt");
    CreateTimer(1.0, Timer_CheckMapReload, 0, TIMER_REPEAT);
}

public void OnConfigsExecuted() {
    clean_up_weapons = cvar_clean_up_weapons.BoolValue;
    if (clean_up_weapons) {
        for (int c = MaxClients + 1; c < GetMaxEntities(); c++) {
            RemoveIfWeapon(c);
        }
    }

    int new_map_reload_interval = cvar_autorestart_map.IntValue;
    if (new_map_reload_interval != map_reload_interval){
        if (new_map_reload_interval != 0) {
            map_reload_time = GetTime() + new_map_reload_interval;
            map_reload_interval = new_map_reload_interval;
        } else if (new_map_reload_interval == 0) {
            map_reload_time = 0;
        }
    }

    map_change_delay = cvar_mapchange_delay.IntValue;
}

public void CvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue) {
    OnConfigsExecuted();
}

public Action Timer_CheckMapReload(Handle timer) {
    if (map_reload_time != 0) {
        int time = GetTime();
        if(time >= map_reload_time) {
            map_reload_time = time + map_change_delay + map_reload_interval;
            GFLDM_PrintToChatAll("%t", "Map Restarting in...", map_change_delay);
            CreateTimer(1.0, Timer_ReloadMap, time + map_change_delay, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action Timer_ReloadMap(Handle timer, any data) {
    int change_time = data;
    int time = GetTime();
    if (time < change_time) {
        GFLDM_PrintToChatAll("%t", "Map Restarting in...", change_time - time);
    } else {
        char current_map[PLATFORM_MAX_PATH];
        change_time = time + map_reload_interval;
        GetCurrentMap(current_map, sizeof(current_map));
        ForceChangeLevel(current_map, "GFLDM Map Restart");
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public Action ConCmd_Message(int client, int args) {
    char msg_type[64];
    GetCmdArg(1, msg_type, sizeof(msg_type));
    Handle hMessage = StartMessageOne(msg_type, client);
    BfWriteByte(hMessage, 1);
    BfWriteString(hMessage, "Hello world");
    EndMessage();

    return Plugin_Handled;
}

public void OnMapStart() {
    ConVar bot_quota = FindConVar("bot_quota");
    bot_quota.Flags = bot_quota.Flags & (~FCVAR_NOTIFY);
    RemovePhysicsProps();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    RemovePhysicsProps();
}

public void OnClientPutInServer(int client) {
    if (IsValidEdict(client)) {
        SDKHook(client, SDKHook_WeaponDropPost, SDKHook_OnWeaponDropPost);
    }
}

public void OnEntityCreated(int entity) {
    if (IsValidEdict(entity) && clean_up_weapons) {
        char clsname[64];
        if (GetEdictClassname(entity, clsname, sizeof(clsname))) {
            if (StrContains(clsname, "weapon_") != -1) {
                CreateTimer(0.25, Timer_CheckWeapon, entity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public Action Timer_CheckWeapon(Handle timer, any entity) {
    RemoveIfWeapon(entity);
}

void RemoveIfWeapon(int entity) {
    if (IsValidEdict(entity)) {
        char clsname[64];
        if (GetEdictClassname(entity, clsname, sizeof(clsname))) {
            if (StrContains(clsname, "weapon_") != -1) {
                if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", 0) == -1) {
                    RemoveEntity(entity);
                }
            }
        }
    }
}

void RemovePhysicsProps() {
    if (cvar_remove_physics_ents.BoolValue) {
        char clsname[128];
        int max_ents = GetMaxEntities();
        for (int c = 0; c < max_ents; c++) {
            if (IsValidEdict(c)) {
                if (GetEdictClassname(c, clsname, sizeof(clsname))) {
                    if (StrEqual(clsname, "prop_physics_multiplayer")) {
                        RemoveEdict(c);
                    }
                }
            }
        }
    }
}

public void SDKHook_OnWeaponDropPost(int client, int weapon) {
    if (IsValidEntity(weapon) && clean_up_weapons) {
        RemoveEntity(weapon);
    }
}