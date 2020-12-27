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
    public native void AddSound(const char[] sound_file, float delay=0.0, int level=SNDLEVEL_NORMAL, float volume=1.0);
    public native void AddAmbientSound(float origin[3], const char[] sound_file, float delay=0.0, int level=SNDLEVEL_NORMAL, float volume=1.0);

    public native void Play();
    public native void TE_Send();
    public native void EmitAmbientSound(float origin[3], const char[] sound_file, int level=SNDLEVEL_NORMAL, float volume=1.0);
    public native void EmitSound(const char[] sound_file, int level=SNDLEVEL_NORMAL, float volume=1.0);
}

native GFLDMAnimation GFLDM_StartAnimOne(int client);
native GFLDMAnimation GFLDM_StartAnimAll();