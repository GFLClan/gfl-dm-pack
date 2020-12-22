#if defined _gfldm_anim_included
    #endinput
#endif
#define _gfldm_anim_included

typedef AnimationFunction = function void (DataPack data);

enum ExplosionType {
    ExplosionNormal,
    ExplosionMassive
}

methodmap GFLDMAnimation < Handle {
    public native GFLDMAnimation();

    public native void AddTimedCallback(AnimationFunction callback, DataPack anim_data, float delay=0.0);
    public native void AddExplosion(ExplosionType type, float pos[3], float delay=0.0);
    public native void AddLightning(float origin[3], float dest[3], float delay=0.0);

    public native void Play();
}
