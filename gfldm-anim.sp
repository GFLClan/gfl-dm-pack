#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gfldm>
#include <gfldm-anim>

public Plugin myinfo = {
    name = "GFLDM Animation",
    author = "Dreae",
    description = "Helpers for timing scripted events",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

#define EXPLODE_SOUND_LOUD "ambient/explosions/explode_9.wav"
#define EXPLODE_SOUND      "ambient/explosions/explode_8.wav"

int explosion_sprite;
int smoke_sprite;
int lightning_sprite;

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_anim_version");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("GFLDMAnimation.GFLDMAnimation", native_CreateAnimation);
    CreateNative("GFLDMAnimation.AddTimedCallback", native_AddAnimCallback);
    CreateNative("GFLDMAnimation.AddExplosion", native_AddExplosion);
    CreateNative("GFLDMAnimation.AddLightning", native_AddLightning);
    CreateNative("GFLDMAnimation.Play", native_Play);
    RegPluginLibrary("gfldm-anim");
}

public void OnMapStart() {
    PrecacheSound(EXPLODE_SOUND_LOUD, true);
    PrecacheSound(EXPLODE_SOUND, true);
    explosion_sprite = PrecacheModel("sprites/plasma.vmt");
    smoke_sprite = PrecacheModel("sprites/steam1.vmt");
    lightning_sprite = PrecacheModel("sprites/lgtning.vmt");
}

public any native_CreateAnimation(Handle plugin, int numParams) {
    return new DataPack();
}

public int native_AddAnimCallback(Handle plugin, int numParams) {
    DataPack self = GetNativeCell(1);
    AnimationFunction callback = GetNativeCell(2);
    DataPack anim_data = GetNativeCell(3);
    float delay = GetNativeCell(4);

    DataPack frame_data = new DataPack();
    frame_data.WriteCell(plugin);
    frame_data.WriteFunction(callback);
    frame_data.WriteCell(anim_data);
    frame_data.Reset();

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddExplosion(Handle plugin, int numParams) {
    float pos[3];
    DataPack self = GetNativeCell(1);
    ExplosionType type = GetNativeCell(2);
    GetNativeArray(3, pos, sizeof(pos));
    float delay = GetNativeCell(4);

    DataPack anim_data = new DataPack();
    anim_data.WriteFloat(pos[0]);
    anim_data.WriteFloat(pos[1]);
    anim_data.WriteFloat(pos[2]);
    anim_data.Reset();

    DataPack frame_data = new DataPack();
    frame_data.WriteCell(INVALID_HANDLE);
    if (type == ExplosionMassive) {
        frame_data.WriteFunction(Anim_ExplodeMassive);
    } else {
        frame_data.WriteFunction(Anim_ExplodeNormal);
    }
    frame_data.WriteCell(anim_data);
    frame_data.Reset();

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddLightning(Handle plugin, int numParams) {
    float origin[3], dest[3];
    DataPack self = GetNativeCell(1);
    GetNativeArray(2, origin, sizeof(origin));
    GetNativeArray(3, dest, sizeof(dest));
    float delay = GetNativeCell(4);

    DataPack anim_data = new DataPack();
    anim_data.WriteFloat(origin[0]);
    anim_data.WriteFloat(origin[1]);
    anim_data.WriteFloat(origin[2]);
    anim_data.WriteFloat(dest[0]);
    anim_data.WriteFloat(dest[1]);
    anim_data.WriteFloat(dest[2]);
    anim_data.Reset();

    DataPack frame_data = new DataPack();
    frame_data.WriteCell(INVALID_HANDLE);
    frame_data.WriteFunction(Anim_Lightning);
    frame_data.WriteCell(anim_data);
    frame_data.Reset();

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_Play(Handle plugin, int numParams) {
    DataPack self = GetNativeCell(1);
    self.Reset();
    
    float max_delay = 0.0;
    DataPack cleanup_data = new DataPack();
    do {
        float delay = self.ReadFloat();
        if (delay > max_delay) {
            max_delay = delay;
        }
        DataPack frame_data = self.ReadCell();
        cleanup_data.WriteCell(frame_data);
        
        CreateTimer(delay, Timer_PlayFrame, frame_data, TIMER_FLAG_NO_MAPCHANGE);
    } while (self.IsReadable(0));

    cleanup_data.Reset();
    CreateTimer(max_delay + 1.0, Timer_Cleanup, cleanup_data);
    delete self;
}

Action Timer_PlayFrame(Handle timer, any data) {
    DataPack frame_data = data;
    Handle plugin = frame_data.ReadCell();
    Function callback = frame_data.ReadFunction();
    DataPack anim_data = frame_data.ReadCell();

    Call_StartFunction(plugin, callback);
    Call_PushCell(anim_data);
    Call_Finish();

    delete anim_data;
}

Action Timer_Cleanup(Handle time, any data) {
    DataPack cleanup_data = data;

    do {
        DataPack frame_data = cleanup_data.ReadCell();
        delete frame_data;
    } while(cleanup_data.IsReadable(0));

    delete cleanup_data;
}

void Anim_ExplodeMassive(DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();

    float normal[3] = {0.0, 0.0, 1.0};

    TE_SetupEnergySplash(origin, normal, false);

    TE_SetupExplosion(origin, explosion_sprite, 5.0, 5, 0, 150, 140, normal);
    TE_SendToAll();

    TE_SetupSmoke(origin, smoke_sprite, 10.0, 3);
    TE_SendToAll();

    EmitAmbientSound(EXPLODE_SOUND_LOUD, origin, 0, SNDLEVEL_GUNFIRE);
}

void Anim_ExplodeNormal(DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();
    float normal[3] = {0.0, 0.0, 1.0};

    TE_SetupExplosion(origin, explosion_sprite, 5.0, 1, 0, 50, 40, normal);
    TE_SendToAll();

    TE_SetupSmoke(origin, smoke_sprite, 10.0, 3);
    TE_SendToAll();

    EmitAmbientSound(EXPLODE_SOUND, origin, 0, SNDLEVEL_NORMAL);
}

void Anim_Lightning(DataPack anim_data) {
    float origin[3],  dest[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();

    dest[0] = anim_data.ReadFloat();
    dest[1] = anim_data.ReadFloat();
    dest[2] = anim_data.ReadFloat();

    float normal[3];
    SubtractVectors(dest, origin, normal);
    NormalizeVector(normal, normal);

    TE_Start("GaussExplosion");
	TE_WriteVector("m_vecOrigin[0]", dest);
	TE_WriteNum("m_nType", 1);
	TE_WriteVector("m_vecDirection", normal);
    TE_SendToAll();

    int color[4] = {255, 255, 255, 255};
    TE_SetupBeamPoints(origin, dest, lightning_sprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
}