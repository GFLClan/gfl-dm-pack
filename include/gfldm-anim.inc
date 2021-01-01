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

#if defined _gfldm_anim_included
    #endinput
#endif
#define _gfldm_anim_included

typedef AnimationFunction = function void (GFLDMAnimation anim, DataPack data);

enum ExplosionType {
    ExplosionNormal,
    ExplosionMassive
}

enum AnimationTarget {
    AnimTarget_One,
    AnimTarget_All
}

methodmap GFLDMAnimation < Handle {
    public native void AddTimedCallback(AnimationFunction callback, DataPack anim_data, float delay=0.0);
    public native void AddExplosion(float pos[3], float delay=0.0, ExplosionType type=ExplosionNormal);
    public native void AddLightning(float origin[3], float dest[3], float delay=0.0);
    public native void AddSound(const char[] sound_file, float delay=0.0, int level=75, float volume=1.0);
    public native void AddAmbientSound(float origin[3], const char[] sound_file, float delay=0.0, int level=75, float volume=1.0);
    public native void AddFire(float origin[3], float lifetime, float delay=0.0, float firesize=15.0);
    public native void AddTesla(float origin[3], float lifetime, float delay=0.0, float radius=30.0, float interval_min=0.1, float interval_max=0.5, int beamcount_min=2, int beamcount_max=9, float thick_min=2.0, float thick_max=9.0, float lifetime_min=0.2, float lifetime_max=0.5);
    public native void Play();
    public native void TE_Send();
    public native void EmitAmbientSound(float origin[3], const char[] sound_file, int level=75, float volume=1.0);
    public native void EmitSound(const char[] sound_file, int level=75, float volume=1.0);
}

methodmap GFLDMHudElement < Handle {
    public native GFLDMHudElement(int client, float x, float y);
    public native void SetColor(int color[4]);
    public native void SetBody();
    public native void Draw(float hold_time, const char[] fmt, any ...);
    public native void Clear();
    public native void CloseTrie();
}

native GFLDMAnimation GFLDM_StartAnimOne(int client);
native GFLDMAnimation GFLDM_StartAnimAll();