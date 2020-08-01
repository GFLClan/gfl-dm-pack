
#pragma semicolon 1

#include <sourcemod>
#include <sdktools_sound>
#include <gfldm>

public Plugin myinfo = {
    name = "GFL DM Sounds",
    author = "Dreae",
    description = "DM sound improvements",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

ConVar cvar_block_sounds;

public void OnPluginStart() {
    cvar_block_sounds = CreateConVar("gfldm_block_sounds", "1", "Blocks itempickup sounds");
    AddNormalSoundHook(Hook_NormalSound);

    AutoExecConfig();
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
