#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo = {
    name = "GFL DM Core",
    author = "Dreae",
    description = "Basic DM QoL improvements",
    version = "1.0.0", 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

public void OnMapStart() {
    ConVar bot_quota = FindConVar("bot_quota");
    bot_quota.Flags = bot_quota.Flags & (~FCVAR_NOTIFY);
}