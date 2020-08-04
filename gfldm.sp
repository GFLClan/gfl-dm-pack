#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <gfldm>

public Plugin myinfo = {
    name = "GFLDM Core",
    author = "Dreae",
    description = "Basic DM QoL improvements",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

ConVar cvar_remove_physics_ents;

public void OnPluginStart() {
    cvar_remove_physics_ents = CreateConVar("gfldm_remove_physics_ents", "1", "Remove CPhysicsPropMultiplayer");
    DEFINE_VERSION("gfldm_version")

    HookEvent("round_start", Event_RoundStart);
    RegConsoleCmd("sm_usermessage", ConCmd_Message);

    for (int c = 1; c <= MaxClients; c++) {
        if (IsClientInGame(c)) {
            OnClientPutInServer(c);
        }
    }

    for (int c = MaxClients + 1; c < GetMaxEntities(); c++) {
        RemoveIfWeapon(c);
    }

    AutoExecConfig();
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
    if (IsValidEdict(entity)) {
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
    if (IsValidEntity(weapon)) {
        RemoveEntity(weapon);
    }
}