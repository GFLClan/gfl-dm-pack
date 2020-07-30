#if defined _gfldm_stats_included
    #endinput
#endif
#define _gfldm_stats_included

enum struct PlayerHitboxStats {
    int head;
    int chest;
    int stomach;
    int left_arm;
    int right_arm;
    int left_leg;
    int right_leg;
}

enum struct PlayerStats {
    int shots;
    int hits;
    int kills;
    int headshots;
    int deaths;
    PlayerHitboxStats hitboxes;
}

native void GFLDM_GetPlayerStats(int client, any playerStats);