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

#define EXPLODE_SOUND_LOUD   "ambient/explosions/explode_9.wav"
#define EXPLODE_SOUND        "ambient/explosions/explode_8.wav"
#define SNDCHAN_AMBIENT      8
#define TESLA_SPRITE         "sprites/physbeam.vmt"

int explosion_sprite;
int smoke_sprite;
int lightning_sprite;

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_anim_version");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("GFLDM_StartAnimAll", native_CreateAnimation);
    CreateNative("GFLDM_StartAnimOne", native_CreateSingleAnimation);
    CreateNative("GFLDMAnimation.AddTimedCallback", native_AddAnimCallback);
    CreateNative("GFLDMAnimation.AddExplosion", native_AddExplosion);
    CreateNative("GFLDMAnimation.AddLightning", native_AddLightning);
    CreateNative("GFLDMAnimation.AddAmbientSound", native_AddAmbientSound);
    CreateNative("GFLDMAnimation.AddSound", native_AddSound);
    CreateNative("GFLDMAnimation.AddFire", native_AddFire);
    CreateNative("GFLDMAnimation.AddTesla", native_AddTesla);
    CreateNative("GFLDMAnimation.Play", native_Play);
    CreateNative("GFLDMAnimation.TE_Send", native_TE_Send);
    CreateNative("GFLDMAnimation.EmitAmbientSound", native_EmitAmbientSound);
    CreateNative("GFLDMAnimation.EmitSound", native_EmitSound);

    CreateNative("GFLDMHudElement.GFLDMHudElement", native_HudElement);
    CreateNative("GFLDMHudElement.SetColor", native_SetColor);
    CreateNative("GFLDMHudElement.Draw", native_Draw);
    CreateNative("GFLDMHudElement.Clear", native_Clear);
    CreateNative("GFLDMHudElement.CloseTrie", native_CloseHud);

    RegPluginLibrary("gfldm-anim");
}

public void OnMapStart() {
    PrecacheSound(EXPLODE_SOUND_LOUD, true);
    PrecacheSound(EXPLODE_SOUND, true);
    explosion_sprite = PrecacheModel("sprites/plasma.vmt");
    smoke_sprite = PrecacheModel("sprites/steam1.vmt");
    lightning_sprite = PrecacheModel("sprites/lgtning.vmt");
    PrecacheModel(TESLA_SPRITE);
}

public any native_HudElement(Handle plugin, int num_params) {
    int client = GetNativeCell(1);
    float x = GetNativeCell(2);
    float y = GetNativeCell(3);
    int default_color[4] = {255, 255, 255, 255};
    StringMap hud = new StringMap();
    hud.SetValue("client", client);
    hud.SetValue("synchronizer", CreateHudSynchronizer());
    hud.SetValue("x", x);
    hud.SetValue("y", y);
    hud.SetArray("color", default_color, sizeof(default_color));

    return hud;
}

public any native_SetColor(Handle plugin, int num_params) {
    StringMap hud = GFLDM_GetNativeHandle(1);
    int color[4];
    GetNativeArray(2, color, sizeof(color));
    hud.SetArray("color", color, sizeof(color));
}

public any native_Draw(Handle plugin, int num_params) {
    StringMap hud = GFLDM_GetNativeHandle(1);
    float hold_time = GetNativeCell(2);
    int client;
    if (hud.GetValue("client", client) && GFLDM_IsValidClient(client)) {
        Handle synchronizer;
        hud.GetValue("synchronizer", synchronizer);
        float x, y;
        hud.GetValue("x", x);
        hud.GetValue("y", y);

        int color[4];
        hud.GetArray("color", color, sizeof(color));
        
        char buffer[1024];
        int written;
        
        SetGlobalTransTarget(client);
        FormatNativeString(0, 3, 4, sizeof(buffer), written, buffer);
        SetGlobalTransTarget(LANG_SERVER);

        SetHudTextParams(x, y, hold_time, color[0], color[1], color[2], color[3]);
        ShowSyncHudText(client, synchronizer, buffer);
    }
}

public any native_Clear(Handle plugin, int num_params) {
    StringMap hud = GFLDM_GetNativeHandle(1);
    int client;
    if (hud.GetValue("client", client) && GFLDM_IsValidClient(client)) {
        Handle synchronizer;
        hud.GetValue("synchronizer", synchronizer);
        ClearSyncHud(client, synchronizer);
    }
}

public any native_CloseHud(Handle plugin, int num_params) {
    StringMap hud = GFLDM_GetNativeHandle(1);
    Handle synchronizer;
    if (hud.GetValue("synchronizer", synchronizer) && synchronizer != INVALID_HANDLE) {
        delete synchronizer;
    }

    delete hud;
}

public any native_CreateAnimation(Handle plugin, int numParams) {
    DataPack anim = new DataPack();
    anim.WriteCell(AnimTarget_All);
    anim.WriteCell(0);

    return anim;
}

public any native_CreateSingleAnimation(Handle plugin, int numParams) {
    int target = GetNativeCell(1);
    DataPack anim = new DataPack();
    anim.WriteCell(AnimTarget_One);
    anim.WriteCell(target);

    return anim;
}

public int native_AddAnimCallback(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);
    AnimationFunction callback = GetNativeCell(2);
    DataPack anim_data = GFLDM_GetNativeHandle(3);
    float delay = GetNativeCell(4);

    DataPack frame_data = MakeFrameData(self, plugin, callback, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddExplosion(Handle plugin, int numParams) {
    float pos[3];
    DataPack self = GFLDM_GetNativeHandle(1);
    GetNativeArray(2, pos, sizeof(pos));
    float delay = GetNativeCell(3);
    ExplosionType type = GetNativeCell(4);

    DataPack anim_data = new DataPack();
    anim_data.WriteFloat(pos[0]);
    anim_data.WriteFloat(pos[1]);
    anim_data.WriteFloat(pos[2]);
    anim_data.Reset();

    DataPack frame_data;
    if (type == ExplosionMassive) {
        frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_ExplodeMassive, anim_data);
    } else {
        frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_ExplodeNormal, anim_data);
    }

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddLightning(Handle plugin, int numParams) {
    float origin[3], dest[3];
    DataPack self = GFLDM_GetNativeHandle(1);
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

    DataPack frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_Lightning, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddAmbientSound(Handle plugin, int numParams) {
    float origin[3];
    char sound_file[PLATFORM_MAX_PATH];
    DataPack self = GFLDM_GetNativeHandle(1);
    GetNativeArray(2, origin, sizeof(origin));
    GetNativeString(3, sound_file, sizeof(sound_file));
    float delay = GetNativeCell(4);
    int level = GetNativeCell(5);
    float volume = GetNativeCell(6);

    DataPack anim_data = new DataPack();
    anim_data.WriteFloat(origin[0]);
    anim_data.WriteFloat(origin[1]);
    anim_data.WriteFloat(origin[2]);
    anim_data.WriteString(sound_file);
    anim_data.WriteCell(level);
    anim_data.WriteFloat(volume);
    anim_data.Reset();

    DataPack frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_EmitAmbient, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddSound(Handle plugin, int numParams) {
    char sound_file[PLATFORM_MAX_PATH];
    DataPack self = GFLDM_GetNativeHandle(1);
    GetNativeString(2, sound_file, sizeof(sound_file));
    float delay = GetNativeCell(3);
    int level = GetNativeCell(4);
    float volume = GetNativeCell(5);

    DataPack anim_data = new DataPack();
    anim_data.WriteString(sound_file);
    anim_data.WriteCell(level);
    anim_data.WriteFloat(volume);
    anim_data.Reset();

    DataPack frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_EmitSound, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddFire(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);
    if (GetAnimTarget(self) != AnimTarget_All) {
        ThrowNativeError(SP_ERROR_NATIVE, "'AddFire' may only be used on animations created with 'GFLDM_StartAnimAll'");
    }

    float origin[3];
    GetNativeArray(2, origin, sizeof(origin));
    float lifetime = GetNativeCell(3);
    float delay = GetNativeCell(4);
    float firesize = GetNativeCell(5);


    DataPack anim_data = new DataPack();
    anim_data.WriteFloat(origin[0]);
    anim_data.WriteFloat(origin[1]);
    anim_data.WriteFloat(origin[2]);
    anim_data.WriteFloat(lifetime);
    anim_data.WriteFloat(firesize);
    anim_data.Reset();

    DataPack frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_Fire, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddTesla(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);
    if (GetAnimTarget(self) != AnimTarget_All) {
        ThrowNativeError(SP_ERROR_NATIVE, "'AddTesla' may only be used on animations created with 'GFLDM_StartAnimAll'");
    }

    float origin[3];
    GetNativeArray(2, origin, sizeof(origin));
    float lifetime = GetNativeCell(3);
    float delay = GetNativeCell(4);

    float radius = GetNativeCell(5);
    float interval_min = GetNativeCell(6);
    float interval_max = GetNativeCell(7);
    int beamcount_min = GetNativeCell(8);
    int beamcount_max = GetNativeCell(9);
    float thick_min = GetNativeCell(10);
    float thick_max = GetNativeCell(11);
    float lifetime_min = GetNativeCell(12);
    float lifetime_max = GetNativeCell(13);

    DataPack anim_data = new DataPack();
    anim_data.WriteFloat(origin[0]);
    anim_data.WriteFloat(origin[1]);
    anim_data.WriteFloat(origin[2]);
    anim_data.WriteFloat(lifetime);
    anim_data.WriteFloat(radius);
    anim_data.WriteFloat(interval_min);
    anim_data.WriteFloat(interval_max);
    anim_data.WriteCell(beamcount_min);
    anim_data.WriteCell(beamcount_max);
    anim_data.WriteFloat(thick_min);
    anim_data.WriteFloat(thick_max);
    anim_data.WriteFloat(lifetime_min);
    anim_data.WriteFloat(lifetime_max);
    anim_data.Reset();

    DataPack frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_Tesla, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

AnimationTarget GetAnimTarget(DataPack anim) {
    DataPackPos pos = anim.Position;
    anim.Reset();

    AnimationTarget target = anim.ReadCell();
    anim.Position = pos;

    return target;
}

int GetAnimClient(DataPack anim) {
    DataPackPos pos = anim.Position;
    anim.Reset();

    anim.ReadCell();
    int client = anim.ReadCell();
    anim.Position = pos;

    return client;
}

DataPack MakeFrameData(DataPack anim, Handle plugin, Function callback, DataPack anim_data) {
    DataPack frame_data = new DataPack();
    frame_data.WriteCell(plugin);
    frame_data.WriteFunction(callback);
    frame_data.WriteCell(anim);
    frame_data.WriteCell(anim_data);
    frame_data.Reset();

    return frame_data;
}

public int native_Play(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);
    self.Reset();
    self.ReadCell();
    self.ReadCell();
    
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

    cleanup_data.WriteCell(self);
    cleanup_data.Reset();
    CreateTimer(max_delay + 1.0, Timer_Cleanup, cleanup_data);
}

public int native_TE_Send(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);

    AnimationTarget target = GetAnimTarget(self);
    if (target == AnimTarget_All) {
        TE_SendToAll();
    } else {
        int client = GetAnimClient(self);
        if (GFLDM_IsValidClient(client, false)) {
            TE_SendToClient(client);
        }
    }
}

public int native_EmitAmbientSound(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);
    float origin[3];
    GetNativeArray(2, origin, sizeof(origin));
    char path[PLATFORM_MAX_PATH];
    GetNativeString(3, path, sizeof(path));
    int level = GetNativeCell(4);
    float volume = GetNativeCell(5);

    AnimationTarget target = GetAnimTarget(self);
    if (target == AnimTarget_All) {
        EmitSoundToAll(path, SOUND_FROM_WORLD, SNDCHAN_AMBIENT, level, _, volume, _, _, origin);
    } else {
        int client = GetAnimClient(self);
        if (GFLDM_IsValidClient(client, false)) {
            EmitSoundToClient(client, path, SOUND_FROM_WORLD, SNDCHAN_AMBIENT, level, _, volume, _, _, origin);
        }
    }
}

public int native_EmitSound(Handle plugin, int numParams) {
    DataPack self = GFLDM_GetNativeHandle(1);
    char path[PLATFORM_MAX_PATH];
    GetNativeString(2, path, sizeof(path));
    int level = GetNativeCell(3);
    float volume = GetNativeCell(4);

    AnimationTarget target = GetAnimTarget(self);
    if (target == AnimTarget_All) {
        EmitSoundToAll(path, SOUND_FROM_PLAYER, SNDCHAN_AUTO, level, _, volume);
    } else {
        int client = GetAnimClient(self);
        if (GFLDM_IsValidClient(client, false)) {
            EmitSoundToClient(client, path, SOUND_FROM_PLAYER, SNDCHAN_AUTO, level, _, volume);
        }
    }
}

Action Timer_PlayFrame(Handle timer, any data) {
    DataPack frame_data = data;
    Handle plugin = frame_data.ReadCell();
    Function callback = frame_data.ReadFunction();
    GFLDMAnimation anim = frame_data.ReadCell();
    DataPack anim_data = frame_data.ReadCell();

    Call_StartFunction(plugin, callback);
    Call_PushCell(anim);
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

void Anim_ExplodeMassive(GFLDMAnimation anim, DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();

    float normal[3] = {0.0, 0.0, 1.0};

    TE_SetupEnergySplash(origin, normal, false);

    TE_SetupExplosion(origin, explosion_sprite, 5.0, 5, 0, 150, 140, normal);
    anim.TE_Send();

    TE_SetupSmoke(origin, smoke_sprite, 10.0, 3);
    anim.TE_Send();

    anim.EmitAmbientSound(origin, EXPLODE_SOUND_LOUD, SNDLEVEL_GUNFIRE);
}

void Anim_ExplodeNormal(GFLDMAnimation anim, DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();
    float normal[3] = {0.0, 0.0, 1.0};

    TE_SetupExplosion(origin, explosion_sprite, 5.0, 1, 0, 50, 40, normal);
    anim.TE_Send();

    TE_SetupSmoke(origin, smoke_sprite, 10.0, 3);
    anim.TE_Send();

    anim.EmitAmbientSound(origin, EXPLODE_SOUND);
}

void Anim_Lightning(GFLDMAnimation anim, DataPack anim_data) {
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
    anim.TE_Send();

    int color[4] = {255, 255, 255, 255};
    TE_SetupBeamPoints(origin, dest, lightning_sprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
    anim.TE_Send();
}

void Anim_EmitAmbient(GFLDMAnimation anim, DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();

    char path[PLATFORM_MAX_PATH];
    anim_data.ReadString(path, sizeof(path));
    int level = anim_data.ReadCell();
    float volume = anim_data.ReadFloat();

    anim.EmitAmbientSound(origin, path, level, volume);
}

void Anim_EmitSound(GFLDMAnimation anim, DataPack anim_data) {
    char path[PLATFORM_MAX_PATH];
    anim_data.ReadString(path, sizeof(path));
    int level = anim_data.ReadCell();
    float volume = anim_data.ReadFloat();

    anim.EmitSound(path, level, volume);
}

void Anim_Fire(GFLDMAnimation anim, DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();
    float lifetime = anim_data.ReadFloat();
    float firesize = anim_data.ReadFloat();
    int fire = CreateEntityByName("env_fire");
    if(IsValidEdict(fire)) {
        char s_firesize[12];
        FloatToString(firesize, s_firesize, sizeof(s_firesize));
        DispatchKeyValue(fire, "damagescale", "0.0");
        
        DispatchKeyValue(fire, "Name", NULL_STRING);
        DispatchKeyValue(fire, "health", "1000");
        DispatchKeyValue(fire, "fireattack", "0");
        DispatchKeyValue(fire, "firetype", "0");
        DispatchKeyValue(fire, "flags", "136");
        DispatchSpawn(fire);
        DispatchKeyValue(fire, "firesize", s_firesize);
        TeleportEntity(fire, origin, NULL_VECTOR, NULL_VECTOR);
        ActivateEntity(fire);
        AcceptEntityInput(fire, "StartFire");
        CreateTimer(lifetime, Timer_KillEnt, fire, TIMER_FLAG_NO_MAPCHANGE);
    } else {
        LogError("Failed to create entity env_fire!");
    }
}

void Anim_Tesla(GFLDMAnimation anim, DataPack anim_data) {
    float origin[3];
    origin[0] = anim_data.ReadFloat();
    origin[1] = anim_data.ReadFloat();
    origin[2] = anim_data.ReadFloat();
    float lifetime = anim_data.ReadFloat();
    float radius = anim_data.ReadFloat();
    float interval_min = anim_data.ReadFloat();
    float interval_max = anim_data.ReadFloat();
    int beamcount_min = anim_data.ReadCell();
    int beamcount_max = anim_data.ReadCell();
    float thick_min = anim_data.ReadFloat();
    float thick_max = anim_data.ReadFloat();
    float lifetime_min = anim_data.ReadFloat();
    float lifetime_max = anim_data.ReadFloat();
    int tesla = CreateEntityByName("point_tesla");
    if (IsValidEdict(tesla)) {
        char s_beam_min[12], s_beam_max[12];
        IntToString(beamcount_min, s_beam_min, sizeof(s_beam_min));
        IntToString(beamcount_max, s_beam_max, sizeof(s_beam_max));
        DispatchKeyValueFloat(tesla, "m_flRadius", radius);
        DispatchKeyValue(tesla, "m_SoundName", "DoSpark");
        DispatchKeyValue(tesla, "beamcount_min", s_beam_min);
        DispatchKeyValue(tesla, "beamcount_max", s_beam_max);
        DispatchKeyValue(tesla, "texture", TESLA_SPRITE);
        DispatchKeyValue(tesla, "m_Color", "255 255 255");
        DispatchKeyValueFloat(tesla, "thick_min", thick_min);
        DispatchKeyValueFloat(tesla, "thick_max", thick_max);
        DispatchKeyValueFloat(tesla, "lifetime_min", lifetime_min);
        DispatchKeyValueFloat(tesla, "lifetime_max", lifetime_max);
        DispatchKeyValueFloat(tesla, "interval_min", interval_min);
        DispatchKeyValueFloat(tesla, "interval_max", interval_max);
        DispatchSpawn(tesla);
        TeleportEntity(tesla, origin, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(tesla, "TurnOn");
        AcceptEntityInput(tesla, "DoSpark");

        DataPack spark_data = new DataPack();
        spark_data.WriteFloat(interval_min);
        spark_data.WriteFloat(interval_max);
        spark_data.WriteCell(tesla);
        CreateTimer(GetRandomFloat(interval_min, interval_max), Timer_Spark, spark_data);
        CreateTimer(lifetime, Timer_KillEnt, tesla, TIMER_FLAG_NO_MAPCHANGE);
    } else {
        LogError("Failed to create point_tesla");
    }
}

Action Timer_Spark(Handle timer, any data) {
    DataPack spark_data = data;
    spark_data.Reset();
    float lifetime_min = spark_data.ReadFloat();
    float lifetime_max = spark_data.ReadFloat();
    int tesla = spark_data.ReadCell();
    if (IsValidEdict(tesla)) {
        if (AcceptEntityInput(tesla, "DoSpark")){
            CreateTimer(GetRandomFloat(lifetime_min, lifetime_max), Timer_Spark, spark_data);
        } else {
            delete spark_data;
        }
    } else {
        delete spark_data;
    }

    return Plugin_Stop;
}

Action Timer_KillEnt(Handle timer, any data) {
    int ent = data;
    if(IsValidEdict(ent)) {
        AcceptEntityInput(ent, "Kill");
        RemoveEdict(ent);
    }
    return Plugin_Stop;
}