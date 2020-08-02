
#pragma semicolon 1

#include <sourcemod>
#include <sdktools_sound>
#include <gfldm>

public Plugin myinfo = {
    name = "GFLDM Sounds",
    author = "Dreae",
    description = "DM sound improvements",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

ConVar cvar_block_sounds;
ConVar cvar_spawn_sounds;
ConVar cvar_kill_sounds;

public void OnPluginStart() {
    DEFINE_VERSION("gfldm_sounds_version")
    cvar_block_sounds = CreateConVar("gfldm_block_sounds", "1", "Blocks itempickup sounds");
    cvar_spawn_sounds = CreateConVar("gfldm_spawn_sounds", "1", "Emit sound from players after spawn");
    cvar_kill_sounds = CreateConVar("gfldm_kill_sounds", "1", "Emit sound to player on kills");
    AddNormalSoundHook(Hook_NormalSound);
    HookEvent("player_spawn", Hook_PlayerSpawn);
    HookEvent("player_death", Hook_PlayerDeath);

    AutoExecConfig();
}

public void OnMapStart() {
    PrecacheSound("buttons/button19.wav", true);
    PrecacheSound("buttons/bell1.wav", true);
}

public void Hook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    if (cvar_spawn_sounds.BoolValue) {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (GFLDM_IsValidClient(client, true)) {
            CreateTimer(0.1, Timer_EmitSpawnSound, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    if (cvar_kill_sounds.BoolValue) {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (attacker != victim && GFLDM_IsValidClient(attacker)) {
            EmitSoundToClient(attacker, "buttons/bell1.wav", attacker, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
        }
    }
}

public Action Timer_EmitSpawnSound(Handle timer, any client) {
    EmitSoundToAll("buttons/button19.wav", client);

    return Plugin_Stop;
}

public Action Hook_NormalSound(
    int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], 
    int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, 
    char soundEntry[PLATFORM_MAX_PATH], int &seed
) {
    if (cvar_block_sounds.BoolValue) {
        if (StrEqual(sample, "items/itempickup.wav") || StrEqual(sample, "items/ammopickup.wav")) {
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}
