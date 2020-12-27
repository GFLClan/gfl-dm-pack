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
    CreateNative("GFLDMAnimation.Play", native_Play);
    CreateNative("GFLDMAnimation.TE_Send", native_TE_Send);
    CreateNative("GFLDMAnimation.EmitAmbientSound", native_EmitAmbientSound);
    CreateNative("GFLDMAnimation.EmitSound", native_EmitSound);
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
    DataPack self = GetNativeCell(1);
    AnimationFunction callback = GetNativeCell(2);
    DataPack anim_data = GetNativeCell(3);
    float delay = GetNativeCell(4);

    DataPack frame_data = MakeFrameData(self, plugin, callback, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddExplosion(Handle plugin, int numParams) {
    float pos[3];
    DataPack self = GetNativeCell(1);
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

    DataPack frame_data = MakeFrameData(self, INVALID_HANDLE, Anim_Lightning, anim_data);

    self.WriteFloat(delay);
    self.WriteCell(frame_data);
    return 0;
}

public int native_AddAmbientSound(Handle plugin, int numParams) {
    float origin[3];
    char sound_file[PLATFORM_MAX_PATH];
    DataPack self = GetNativeCell(1);
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
    DataPack self = GetNativeCell(1);
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
    DataPack self = GetNativeCell(1);
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
    DataPack self = GetNativeCell(1);
    DataPackPos pos = self.Position;
    self.Reset();

    AnimationTarget target = self.ReadCell();
    if (target == AnimTarget_All) {
        TE_SendToAll();
    } else {
        int client = self.ReadCell();
        if (GFLDM_IsValidClient(client, false)) {
            TE_SendToClient(client);
        }
    }

    self.Position = pos;
}

public int native_EmitAmbientSound(Handle plugin, int numParams) {
    DataPack self = GetNativeCell(1);
    float origin[3];
    GetNativeArray(2, origin, sizeof(origin));
    char path[PLATFORM_MAX_PATH];
    GetNativeString(3, path, sizeof(path));
    int level = GetNativeCell(4);
    float volume = GetNativeCell(5);

    DataPackPos pos = self.Position;
    self.Reset();

    AnimationTarget target = self.ReadCell();
    if (target == AnimTarget_All) {
        EmitSoundToAll(path, SOUND_FROM_WORLD, SNDCHAN_AMBIENT, level, _, volume, _, _, origin);
    } else {
        int client = self.ReadCell();
        if (GFLDM_IsValidClient(client, false)) {
            EmitSoundToClient(client, path, SOUND_FROM_WORLD, SNDCHAN_AMBIENT, level, _, volume, _, _, origin);
        }
    }

    self.Position = pos;
}

public int native_EmitSound(Handle plugin, int numParams) {
    DataPack self = GetNativeCell(1);
    char path[PLATFORM_MAX_PATH];
    GetNativeString(2, path, sizeof(path));
    int level = GetNativeCell(3);
    float volume = GetNativeCell(4);

    DataPackPos pos = self.Position;
    self.Reset();

    AnimationTarget target = self.ReadCell();
    if (target == AnimTarget_All) {
        EmitSoundToAll(path, SOUND_FROM_PLAYER, SNDCHAN_AUTO, level, _, volume);
    } else {
        int client = self.ReadCell();
        if (GFLDM_IsValidClient(client, false)) {
            EmitSoundToClient(client, path, SOUND_FROM_PLAYER, SNDCHAN_AUTO, level, _, volume);
        }
    }

    self.Position = pos;
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