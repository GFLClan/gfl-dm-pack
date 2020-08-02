#pragma semicolon 1

#include <sourcemod>
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

    AutoExecConfig();
}

public void OnMapStart() {
    ConVar bot_quota = FindConVar("bot_quota");
    bot_quota.Flags = bot_quota.Flags & (~FCVAR_NOTIFY);
    RemovePhysicsProps();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    RemovePhysicsProps();
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