#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gfldm>
#include <gfldm-stats>
#include <gfldm-chat>
#include <gfldm-anim>

#define THUNDER_STRIKE_ROLLING "gfldm/thunder1.mp3"
#define THUNDER_ROLLING        "gfldm/thunder2.mp3"
#define THUNDER_STRIKE         "gfldm/thunder3.mp3"

public Plugin myinfo = {
    name = "GFLDM Quake Sounds",
    author = "Dreae",
    description = "Plays sounds for various in-game events",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

float last_headshot_time[MAXPLAYERS + 1] = {0.0, ...};
int consecutive_headshots[MAXPLAYERS + 1] = {0, ...};

int hattrick_hsreq = 3;
float hattrick_max_delay = 3.0;

PrivateForward stats_forward;

enum AnnouncementConfig {
    AnnounceNone = 0,
    AnnounceAll = 1,
    AnnounceParticipants = 2,
    AnnounceAttacker = 3,
    AnnounceVictim = 4
}

enum struct SoundConfig {
    char sound_file[PLATFORM_MAX_PATH];
    AnnouncementConfig announce;
}

enum struct KillStreakConfig {
    SoundConfig sound_config;
    int kills_req;
}

enum struct SoundSet {
    ArrayList kill_streaks;
    SoundConfig headshot;
    SoundConfig knife;
    SoundConfig hattrick;
    SoundConfig collateral;
}

typedef SoundConfigLoader = function bool (int client, SoundSet sound_set, SoundConfig target_config, any data);
StringMap sound_set_map;

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_quakesounds_version");

    stats_forward = CreateForward(ET_Hook, Param_Cell, Param_Array, Param_Cell, Param_Array, Param_Cell, Param_Array, Param_Cell);
    stats_forward.AddFunction(INVALID_HANDLE, Announce_Collat);
    stats_forward.AddFunction(INVALID_HANDLE, Announce_Streak);
    stats_forward.AddFunction(INVALID_HANDLE, Announce_Headshot);

    sound_set_map = new StringMap();
}

public void OnAllPluginsLoaded() {
    GFLDM_RequireLibrary("gfldm-stats");
    GFLDM_RequireLibrary("gfldm-anim");
    GFLDM_RequireLibrary("gfldm-chat");
}

public void OnMapStart() {
    CacheSound(THUNDER_ROLLING);
    CacheSound(THUNDER_STRIKE);
    CacheSound(THUNDER_STRIKE_ROLLING);

    LoadSoundSets();
}

void CacheSound(const char[] sound) {
    if (PrecacheSound(sound, true)) {
        char path[PLATFORM_MAX_PATH];
        Format(path, sizeof(path), "sound/%s", sound);
        AddFileToDownloadsTable(path);
    } else {
        LogError("Error caching sound %s", sound);
    }
}

void LoadSoundSets() {
    DirectoryListing configs = OpenDirectory("addons/sourcemod/configs/gfl-quake");
    char filename[PLATFORM_MAX_PATH];
    FileType file_type;
    while (configs.GetNext(filename, PLATFORM_MAX_PATH, file_type)) {
        if (file_type == FileType_File) {
            char config_path[PLATFORM_MAX_PATH];
            SoundSet set;
            set.kill_streaks = new ArrayList(512);
            char set_name[64];

            BuildPath(Path_SM, config_path, sizeof(config_path), "configs/gfl-quake/%s", filename);
            LogMessage("Parsing SoundSet %s", config_path);
            KeyValues kv = new KeyValues("SoundSet");
            if (!kv.ImportFromFile(config_path)) {
                LogError("Error parsing SoundSet %s", config_path);
                delete kv;
                continue;
            }
            kv.GotoFirstSubKey(false);

            char buffer[64];
            do {
                kv.GetSectionName(buffer, sizeof(buffer));
                if (StrEqual(buffer, "KillStreaks", false)) {
                    kv.GotoFirstSubKey();
                    
                    do {
                        KillStreakConfig config;
                        if (ParseKVKillStreak(kv, config)) {
                            set.kill_streaks.PushArray(config, sizeof(config));
                        }
                    } while(kv.GotoNextKey());
                    
                    kv.GoBack();
                } else if (StrEqual(buffer, "Headshot", false)) {
                    kv.GotoFirstSubKey();

                    if (!ParseSoundConfig(kv, set.headshot)) {
                        LogError("Error parsing headshot entry");
                    }

                    kv.GoBack();
                } else if (StrEqual(buffer, "SpecialChains", false)) {
                    kv.GotoFirstSubKey();

                    char section_name[32];
                    do {
                        kv.GetSectionName(section_name, sizeof(section_name));
                        if (StrEqual(section_name, "Collateral", false)) {
                            if (!ParseSoundConfig(kv, set.collateral)) {
                                LogError("Error parsing collateral entry");
                            }
                        }
                    } while(kv.GotoNextKey());

                    kv.GoBack();
                } else if (StrEqual(buffer, "Name", false)) {
                    kv.GetString(NULL_STRING, set_name, sizeof(set_name));
                    PrintToServer("Got name %s", set_name);
                }
            } while(kv.GotoNextKey(false));

            delete kv;

            if (strlen(set_name) == 0) {
                LogError("Error parsing SoundSet file %s, you must provide a Name", filename);
            } else {
                sound_set_map.SetArray(set_name, set, sizeof(set));
            }
        }
    }
}

bool ParseSoundConfig(KeyValues kv, SoundConfig config) {
    kv.GetString("SoundFile", config.sound_file, PLATFORM_MAX_PATH, "nan");
    if(StrEqual(config.sound_file, "nan")) {
        LogError("[GFLDM-Quake] Error parsing sound entry, missing SoundFile");
        config.announce = AnnounceNone;
        return false;
    } else {
        char buffer[32];
        CacheSound(config.sound_file);
        kv.GetString("Announce", buffer, sizeof(buffer));
        config.announce = ParseAnnounceValue(buffer);
    }

    return true;
}

bool ParseKVKillStreak(KeyValues kv, KillStreakConfig kill_streak) {
    char buffer[PLATFORM_MAX_PATH];
    kv.GetSectionName(buffer, sizeof(buffer));
    kill_streak.kills_req = StringToInt(buffer);
    if (kill_streak.kills_req == 0) {
        LogError("[GFLDM-Quake] Error parsing Killstreaks entry, %s is not a number", buffer);
        return false;
    }

    kv.GetString("SoundFile", buffer, PLATFORM_MAX_PATH, "nan");
    if(StrEqual(buffer, "nan")) {
        LogError("[GFLDM-Quake] Error parsing Killstreaks entry %d, missing SoundFile", kill_streak.kills_req);
        return false;
    }
    
    return ParseSoundConfig(kv, kill_streak.sound_config);
}

AnnouncementConfig ParseAnnounceValue(const char[] value) {
    if (StrEqual(value, "all", false)) {
        return AnnounceAll;
    } else if (StrEqual(value, "participants", false)) {
        return AnnounceParticipants;
    } else if (StrEqual(value, "victim", false)) {
        return AnnounceVictim;
    } else if (StrEqual(value, "attacker", false)) {
        return AnnounceAttacker;
    } else {
        PrintAnnounceHelp();
        return AnnounceAll;
    }
}

void PrintAnnounceHelp() {
    LogError("[GFLDM-Quake] Error parsing config, invalid value for Announce, defaulting to 'all'");
    LogError("[GFLDM-Quake] valid values are:");
    LogError("=> 'all' - Announce to everyone");
    LogError("=> 'participants' - Announce to victim and attacker");
    LogError("=> 'victim' - Announce only to the victim");
    LogError("=> 'attacker' - Announce only to the attacker");
}

public void GFLDM_OnStatsUpdate(int client, int stats_class, PlayerStats stats, int[] victims, int victim_count) {
    if (stats_class == STATCLASS_RESET) {
        last_headshot_time[client] = 0.0;
        consecutive_headshots[client] = 0;
        return;
    }

    for (int c = 0; c < MaxClients; c++) {
        SoundSet target_sound_set;
        if (GFLDM_IsValidClient(c) && GetClientSoundSet(c, target_sound_set)) {
            Call_StartForward(stats_forward);
            Call_PushCell(c);
            Call_PushArray(target_sound_set, sizeof(target_sound_set));
            Call_PushCell(stats_class);
            Call_PushArray(stats, sizeof(stats));
            Call_PushCell(client);
            Call_PushArray(victims, victim_count);
            Call_PushCell(victim_count);
            Call_Finish();
        }
    }
}

Action Announce_Collat(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (stats_class & STATCLASS_COLLATERAL) {
        PlayAnim_Collat(client, victims, victim_count);
        return OptionalAnnounce(client, attacker, victims, victim_count, sound_set.collateral);
    }

    return Plugin_Continue;
}

Action Announce_Streak(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if ((stats_class & STATCLASS_STREAK) && stats.current_streak > 1) {
        for (int c = 0; c < sound_set.kill_streaks.Length; c++) {
            KillStreakConfig kill_streak;
            sound_set.kill_streaks.GetArray(c, kill_streak, sizeof(kill_streak));
            if (kill_streak.kills_req == stats.current_streak) {
                return OptionalAnnounce(client, attacker, victims, victim_count, kill_streak.sound_config);
            }
        }
    }

    return Plugin_Continue;
}

Action Announce_Headshot(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (stats_class & STATCLASS_HEADSHOTS) {
        return OptionalAnnounce(client, attacker, victims, victim_count, sound_set.headshot);
    }

    return Plugin_Continue;
}

Action OptionalAnnounce(int client, int attacker, int[] victims, int victim_count, SoundConfig config) {
    if (
        config.announce == AnnounceAll
        || (config.announce == AnnounceParticipants && (client == attacker || IsClientVictim(client, victims, victim_count)))
        || (config.announce == AnnounceVictim && IsClientVictim(client, victims, victim_count))
        || (config.announce == AnnounceAttacker && client == attacker)

    ) {
        GFLDM_EmitSound(client, config.sound_file);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void PlayAnim_Collat(int client, int[] victims, int victim_count) {
    GFLDMAnimation anim = GFLDM_StartAnimOne(client);
    for (int i = 0, j = 1; j < victim_count; i++, j++) {
        float start[3], end[3];
        if (!GFLDM_IsValidClient(victims[i], true) || !GFLDM_IsValidClient(victims[j], true)) {
            continue;
        }

        GetClientAbsOrigin(victims[i], start);
        GetClientAbsOrigin(victims[j], end);
        start[2] = start[2] - 35.0;
        end[2] = end[2] - 35.0;
        anim.AddLightning(start, end, 0.08);
    }

    if (GFLDM_IsValidClient(victims[victim_count - 1], true)) {
        float start[3], end[3];
        GetClientAbsOrigin(victims[victim_count - 1], end);

        end[2] = end[2] - 35.0;
        start[0] = end[0] + GetRandomFloat(-125.0, 125.0); 
        start[1] = end[1] + GetRandomFloat(-125.0, 125.0);
        start[2] = end[2] + 700.0;
        anim.AddLightning(start, end);
        anim.AddExplosion(end);
        anim.AddAmbientSound(end, THUNDER_STRIKE_ROLLING, _, SNDLEVEL_GUNFIRE);
    }
    anim.Play();
}

bool IsClientVictim(int client, int[] victims, int victim_count) {
    for (int c = 0; c < victim_count; c++) {
        if (victims[c] == client) {
            return true;
        }
    }

    return false;
}

bool GetClientSoundSet(int client, SoundSet target_sound_set) {
    sound_set_map.GetArray("Standard", target_sound_set, sizeof(target_sound_set));
    return true;
}