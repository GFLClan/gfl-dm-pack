#if defined _gfldm_noscopes_included
    #endinput
#endif
#define _gfldm_noscopes_included

forward void GFLDM_OnNoscope(int attacker, int victim, bool headshot, float distance);

native int GFLDM_GetNoscopes(int client);
native int GFLDM_GetNoscopeHeadshots(int client);