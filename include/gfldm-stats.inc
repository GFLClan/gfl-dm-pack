#if defined _gfldm_stats_included
    #endinput
#endif
#define _gfldm_stats_included

#define STATCLASS_KILLS             (1<<0)
#define STATCLASS_DEATHS            (1<<1)
#define STATCLASS_ACCURACY          (1<<2)
#define STATCLASS_KDR               (1<<3)
#define STATCLASS_NOSCOPES          (1<<4)
#define STATCLASS_STREAK            (1<<5)
#define STATCLASS_HIGHEST_STREAK    (1<<6)
#define STATCLASS_HEADSHOTS         (1<<7)
#define STATCLASS_HITBOXES          (1<<8)
#define STATCLASS_KNIFES            (1<<9)
#define STATCLASS_COLLATERAL        (1<<10)
#define STATCLASS_ONE_DEAG          (1<<11)
#define STATCLASS_AWP_OSOK          (1<<12)
#define STATCLASS_SCOUT_OSOK        (1<<13)
#define STATCLASS_DISCONNECT        0xffffffff
#define STATCLASS_RESET             STATCLASS_DISCONNECT

enum struct PlayerHitboxStats {
    int head;
    int chest;
    int stomach;
    int left_arm;
    int right_arm;
    int left_leg;
    int right_leg;

    void Reset() {
        this.head = 0;
        this.chest = 0;
        this.stomach = 0;
        this.left_arm = 0;
        this.right_arm = 0;
        this.left_leg = 0;
        this.right_leg = 0;
    }
}

enum struct Shot {
    float time;
    bool hit;
    bool kill;
    bool headshot;
    char weapon[32];
}

enum struct PlayerStats {
    int shots;
    int hits;
    int kills;
    int headshots;
    int noscopes;
    int knifes;
    int deaths;
    int current_streak;
    int highest_streak;
    float last_shot;
    float last_kill;
    PlayerHitboxStats hitboxes;

    void Reset() {
        this.shots = 0;
        this.hits = 0;
        this.kills = 0;
        this.headshots = 0;
        this.noscopes = 0;
        this.knifes = 0;
        this.deaths = 0;
        this.current_streak = 0;
        this.highest_streak = 0;
        this.hitboxes.Reset();
    }
}

typedef StatFunction = function void (int client, PlayerStats stats);
native void GFLDM_WithPlayerStats(int client, StatFunction callback);
forward void GFLDM_OnStatsUpdate(int client, int stats_class, PlayerStats stats, int[] victims, int victim_count);