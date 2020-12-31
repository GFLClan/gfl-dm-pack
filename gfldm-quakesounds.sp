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
#include <gfldm>
#include <gfldm-stats>
#include <gfldm-chat>
#include <gfldm-anim>
#include <gfldm-clientprefs>

#define THUNDER_STRIKE_ROLLING "gfldm/thunder1.mp3"
#define THUNDER_ROLLING        "gfldm/thunder2.mp3"
#define THUNDER_STRIKE         "gfldm/thunder3.mp3"

#define SCOUT_ELITE_KREQ     6
#define AWP_ELITE_KREQ       6
#define DEAG_SPREE_KREQ      3

public Plugin myinfo = {
    name = "GFLDM Quake Sounds",
    author = "Dreae",
    description = "Plays sounds for various in-game events",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

enum struct SpecialChain {
    float last_stat_time;
    int stat_count;
    // spcomp pls
    float victim_pos_x[6];
    float victim_pos_y[6];
    float victim_pos_z[6];
}

enum struct SpecialChains {
    SpecialChain rapid_kills;
    SpecialChain headshot;
    SpecialChain rapid_awp_osok;
    SpecialChain rapid_scout_osok;
    SpecialChain awp_osok;
    SpecialChain scout_osok;
    SpecialChain one_deag;
}

SpecialChains player_chain_states[MAXPLAYERS + 1];
GFLDMHudElement hud_hints[MAXPLAYERS + 1];

PrivateForward stats_forward;
PrivateForward quake_forward;

bool quake_enabled[MAXPLAYERS + 1] = {true, ...};
Cookie quake_cookie;

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
    ArrayList rapid_kill_streaks;
    SoundConfig headshot;
    SoundConfig knife;
    SoundConfig hattrick;
    SoundConfig headhunter;
    SoundConfig deag_spree;
    SoundConfig collateral;
    SoundConfig awp_elite;
    SoundConfig scout_elite;
    SoundConfig awp_ace;
    SoundConfig scout_ace;
}

typedef SoundConfigLoader = function bool (int client, SoundSet sound_set, SoundConfig target_config, any data);
StringMap sound_set_map;

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_quakesounds_version");

    stats_forward = CreateForward(ET_Hook, Param_Cell);
    stats_forward.AddFunction(INVALID_HANDLE, Stats_PlayScoutElite);
    stats_forward.AddFunction(INVALID_HANDLE, Stats_PlayAWPElite);
    stats_forward.AddFunction(INVALID_HANDLE, Stats_PlayScoutAce);
    stats_forward.AddFunction(INVALID_HANDLE, Stats_PlayAWPAce);
    stats_forward.AddFunction(INVALID_HANDLE, Stats_PlayDeagSpree);

    quake_forward = CreateForward(ET_Hook, Param_Cell, Param_Array, Param_Cell, Param_Array, Param_Cell, Param_Array, Param_Cell);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_ScoutElite);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_AWPElite);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_ScoutAce);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_AWPAce);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_DeagSpree);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_Headhunter);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_Hattrick);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_Collat);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_RapidStreak);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_Streak);
    quake_forward.AddFunction(INVALID_HANDLE, Announce_Headshot);

    quake_cookie = new Cookie("GFLDM_Quake", "", CookieAccess_Protected);
    FIRE_CLIENT_COOKIES()

    RegConsoleCmd("sm_quake", Cmd_Quake, "Toggle quake sounds");

    sound_set_map = new StringMap();
    LoadTranslations("gfldm_quakesounds.phrases");
    for (int c = 1; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c)) {
            OnClientConnected(c);
        }
    }
}

public void OnClientConnected(int client) {
    hud_hints[client] = new GFLDMHudElement(client, 0.17, 0.88);
    int color[4] = {165, 0, 165, 255};
    hud_hints[client].SetColor(color);
}

public void OnClientDisconnect(int client) {
    hud_hints[client].Close();
    delete hud_hints[client];
}

LOAD_COOKIE_BOOL(quake_cookie, quake_enabled, "on", true)

public Action Cmd_Quake(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    quake_enabled[client] = !quake_enabled[client];
    if (quake_enabled[client]) {
        quake_cookie.Set(client, "on");
        GFLDM_PrintToChat(client, "%t", "Quake enabled");
    } else {
        quake_cookie.Set(client, "off");
        GFLDM_PrintToChat(client, "%t", "Quake disabled");
    }

    return Plugin_Handled;
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
            set.rapid_kill_streaks = new ArrayList(512);
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
                } else if (StrEqual(buffer, "KillChains", false)) {
                    kv.GotoFirstSubKey();

                    do {
                        KillStreakConfig config;
                        if (ParseKVKillStreak(kv, config)) {
                            set.rapid_kill_streaks.PushArray(config, sizeof(config));
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
                        } else if (StrEqual(section_name, "ScoutElite", false)) {
                            if (!ParseSoundConfig(kv, set.scout_elite)) {
                                LogError("Error parsing scout elite entry");
                            }
                        } else if (StrEqual(section_name, "AwpElite", false)) {
                            if (!ParseSoundConfig(kv, set.awp_elite)) {
                                LogError("Error parsing AWP elite entry");
                            }
                        } else if (StrEqual(section_name, "ScoutAce", false)) {
                            if (!ParseSoundConfig(kv, set.scout_ace)) {
                                LogError("Error parsing scout ace entry");
                            }
                        } else if (StrEqual(section_name, "AwpAce", false)) {
                            if (!ParseSoundConfig(kv, set.awp_ace)) {
                                LogError("Error parsing AWP ace entry");
                            }
                        } else if (StrEqual(section_name, "DeagleSpree", false)) {
                            if (!ParseSoundConfig(kv, set.deag_spree)) {
                                LogError("Error parsing deag spree entry");
                            }
                        } else if (StrEqual(section_name, "Headhunter", false)) {
                            if (!ParseSoundConfig(kv, set.headhunter)) {
                                LogError("Error parsing Headhunter entry");
                            }
                        } else if (StrEqual(section_name, "Hattrick", false)) {
                            if (!ParseSoundConfig(kv, set.hattrick)) {
                                LogError("Error parsing Hattrick entry");
                            }
                        }
                    } while(kv.GotoNextKey());

                    kv.GoBack();
                } else if (StrEqual(buffer, "Name", false)) {
                    kv.GetString(NULL_STRING, set_name, sizeof(set_name));
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
    delete configs;
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
        SpecialChains zero;
        player_chain_states[client] = zero;
        return;
    }

    UpdateSpecialChain(stats_class, player_chain_states[client].rapid_scout_osok, STATCLASS_SCOUT_OSOK, 6.0, victims, victim_count);
    UpdateSpecialChain(stats_class, player_chain_states[client].rapid_awp_osok, STATCLASS_AWP_OSOK, 6.0, victims, victim_count);
    UpdateSpecialChain(stats_class, player_chain_states[client].awp_osok, STATCLASS_AWP_OSOK, 0.0, victims, victim_count);
    UpdateSpecialChain(stats_class, player_chain_states[client].scout_osok, STATCLASS_SCOUT_OSOK, 0.0, victims, victim_count);
    UpdateSpecialChain(stats_class, player_chain_states[client].one_deag, STATCLASS_ONE_DEAG, 3.0, victims, victim_count);
    UpdateSpecialChain(stats_class, player_chain_states[client].headshot, STATCLASS_HEADSHOTS, 3.0, victims, victim_count, false);
    UpdateSpecialChain(stats_class, player_chain_states[client].rapid_kills, STATCLASS_KILLS, 1.5, victims, victim_count, false);

    for (int c = 0; c < MaxClients; c++) {
        SoundSet target_sound_set;
        if (GFLDM_IsValidClient(c) && GetClientSoundSet(c, target_sound_set)) {
            Call_StartForward(quake_forward);
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

    Call_StartForward(stats_forward);
    Call_PushCell(client);
    Call_Finish();

    UpdateHudHint(client);
}

void UpdateSpecialChain(int stats_class, SpecialChain chain, int stat_class, float max_time, int[] victims, int victim_count, bool clean=true) {
    if (stats_class & stat_class) {
        float time = GetGameTime();
        if (max_time > 0.0) {
            if (time - chain.last_stat_time > max_time) {
                chain.stat_count = 0;
            }
        }

        for (int c = 0; c < victim_count; c++) {
            int offset = chain.stat_count + c;
            if (offset < 6) {
                float origin[3];
                if (GFLDM_IsValidClient(victims[c], true)) {
                    GetClientAbsOrigin(victims[c], origin);
                }
                chain.victim_pos_x[offset] = origin[0];
                chain.victim_pos_y[offset] = origin[1];
                chain.victim_pos_z[offset] = origin[2];
            }
        }
        chain.stat_count += victim_count;
        chain.last_stat_time = time;
    } else if ((
        (stats_class & STATCLASS_ACCURACY == STATCLASS_ACCURACY) 
        | (stats_class & STATCLASS_KDR == STATCLASS_KDR)
    ) && clean) {
        chain.stat_count = 0;
    } else if (stat_class & STATCLASS_DEATHS) {
        chain.stat_count = 0;
        chain.last_stat_time = 0.0;
    }
}

void UpdateHudHint(int client) {
    if(!GFLDM_IsValidClient(client)) {
        return;
    }

    float time = GetGameTime();
    if (player_chain_states[client].rapid_scout_osok.stat_count >= 3 && time - player_chain_states[client].rapid_scout_osok.last_stat_time < 6.0) {
        hud_hints[client].Draw(600.0, "%t: %d", "Scout Elite", player_chain_states[client].rapid_scout_osok.stat_count);
        CreateTimer(6.0, Timer_UpdateHudHint, client);
    } else if (player_chain_states[client].rapid_awp_osok.stat_count >= 3 && time - player_chain_states[client].rapid_awp_osok.last_stat_time < 6.0) {
        hud_hints[client].Draw(600.0, "%t: %d", "AWP Elite", player_chain_states[client].rapid_awp_osok.stat_count);
        CreateTimer(6.0, Timer_UpdateHudHint, client);
    } else if (player_chain_states[client].scout_osok.stat_count >= 3) {
        hud_hints[client].Draw(600.0, "%t: %d", "Scout Ace", player_chain_states[client].scout_osok.stat_count);
    } else if (player_chain_states[client].awp_osok.stat_count >= 3) {
        hud_hints[client].Draw(600.0, "%t: %d", "AWP Ace", player_chain_states[client].awp_osok.stat_count);
    } else if (player_chain_states[client].one_deag.stat_count >= 2 && time - player_chain_states[client].one_deag.last_stat_time < 3.0) {
        hud_hints[client].Draw(600.0, "%t: %d", "Deagle Spree", player_chain_states[client].one_deag.stat_count);
        CreateTimer(3.0, Timer_UpdateHudHint, client);
    } else {
        hud_hints[client].Clear();
    }
}

Action Timer_UpdateHudHint(Handle timer, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {
        UpdateHudHint(client);
    }
}

Action Stats_PlayScoutElite(int client) {
    if (player_chain_states[client].rapid_scout_osok.stat_count == SCOUT_ELITE_KREQ) {
        PlayAnim_ScoutElite(client);
        player_chain_states[client].rapid_scout_osok.stat_count = 0;
        player_chain_states[client].rapid_scout_osok.last_stat_time = 0.0;
        player_chain_states[client].scout_osok.stat_count = 0;
        player_chain_states[client].scout_osok.last_stat_time = 0.0;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

Action Stats_PlayAWPElite(int client) {
    if (player_chain_states[client].rapid_awp_osok.stat_count == AWP_ELITE_KREQ) {
        PlayAnim_AWPElite(client);
        player_chain_states[client].rapid_awp_osok.stat_count = 0;
        player_chain_states[client].rapid_awp_osok.last_stat_time = 0.0;
        player_chain_states[client].awp_osok.stat_count = 0;
        player_chain_states[client].awp_osok.last_stat_time = 0.0;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

Action Stats_PlayScoutAce(int client) {
    if (player_chain_states[client].scout_osok.stat_count == SCOUT_ELITE_KREQ) {
        PlayAnim_ScoutAce(client);
        player_chain_states[client].scout_osok.stat_count = 0;
        player_chain_states[client].scout_osok.last_stat_time = 0.0;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

Action Stats_PlayAWPAce(int client) {
    if (player_chain_states[client].awp_osok.stat_count == AWP_ELITE_KREQ) {
        PlayAnim_AWPAce(client);
        player_chain_states[client].awp_osok.stat_count = 0;
        player_chain_states[client].awp_osok.last_stat_time = 0.0;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

Action Stats_PlayDeagSpree(int client) {
    if (player_chain_states[client].one_deag.stat_count == DEAG_SPREE_KREQ) {
        PlayAnim_DeagSpree(client);
        player_chain_states[client].one_deag.stat_count = 0;
        player_chain_states[client].one_deag.last_stat_time = 0.0;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}


Action Announce_ScoutElite(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].rapid_scout_osok.stat_count == SCOUT_ELITE_KREQ) {
        GFLDM_PrintToChat(client, "%t", "Announce Scout Elite", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.scout_elite)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            anim.AddSound(sound_set.scout_elite.sound_file);
            anim.AddSound(THUNDER_ROLLING, 1.2, _, 0.6);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_AWPElite(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].rapid_awp_osok.stat_count == AWP_ELITE_KREQ) {
        GFLDM_PrintToChat(client, "%t", "Announce Awp Elite", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.awp_elite)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            anim.AddSound(sound_set.awp_elite.sound_file);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_ScoutAce(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].scout_osok.stat_count == SCOUT_ELITE_KREQ) {
        GFLDM_PrintToChat(client, "%t", "Announce Scout Ace", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.scout_ace)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            anim.AddSound(sound_set.scout_ace.sound_file);
            anim.AddSound(THUNDER_ROLLING, 1.2, _, 0.6);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_AWPAce(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].awp_osok.stat_count == AWP_ELITE_KREQ) {
        GFLDM_PrintToChat(client, "%t", "Announce Awp Ace", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.awp_ace)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            anim.AddSound(sound_set.awp_ace.sound_file);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_DeagSpree(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].one_deag.stat_count == DEAG_SPREE_KREQ) {
        GFLDM_PrintToChat(client, "%t", "Announce Deagle Spree", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.deag_spree)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            anim.AddSound(sound_set.deag_spree.sound_file, _, SNDLEVEL_GUNFIRE);
            anim.AddSound(THUNDER_ROLLING, 1.2, _, 0.6);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_Headhunter(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].headshot.stat_count == 4 && stats_class & STATCLASS_HEADSHOTS) {
        GFLDM_PrintToChat(client, "%t", "Headhunter", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.headhunter)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            if (victim_count > 0 && GFLDM_IsValidClient(victims[0], true)) {
                float origin[3];
                GetClientAbsOrigin(victims[0], origin);
                anim.AddExplosion(origin, _, ExplosionMassive);
            }
            anim.AddSound(sound_set.headhunter.sound_file);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_Hattrick(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].headshot.stat_count == 3 && stats_class & STATCLASS_HEADSHOTS) {
        GFLDM_PrintToChat(client, "%t", "Hattrick", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.hattrick)) {
            GFLDMAnimation anim = GFLDM_StartAnimOne(client);
            if (victim_count > 0 && GFLDM_IsValidClient(victims[0], true)) {
                float origin[3];
                GetClientAbsOrigin(victims[0], origin);
                anim.AddExplosion(origin);
            }
            anim.AddSound(sound_set.hattrick.sound_file);
            anim.Play();
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

Action Announce_Collat(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (stats_class & STATCLASS_COLLATERAL) {
        PlayAnim_Collat(client, victims, victim_count);
        GFLDM_PrintToChat(client, "%t", "Collateral", attacker);
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.collateral)) {
            GFLDM_EmitSound(client, sound_set.collateral.sound_file);
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

Action Announce_RapidStreak(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (player_chain_states[attacker].rapid_kills.stat_count > 1 && stats_class & STATCLASS_KILLS) {
        for (int c = 0; c < sound_set.rapid_kill_streaks.Length; c++) {
            KillStreakConfig kill_streak;
            sound_set.rapid_kill_streaks.GetArray(c, kill_streak, sizeof(kill_streak));
            if (kill_streak.kills_req == player_chain_states[attacker].rapid_kills.stat_count) {
                GFLDM_PrintToChat(client, "%t", "Kill Chain", attacker, player_chain_states[attacker].rapid_kills.stat_count);
                if (ShouldAnnounce(client, attacker, victims, victim_count, kill_streak.sound_config)) {
                    GFLDM_EmitSound(client, kill_streak.sound_config.sound_file);
                    return Plugin_Stop;
                }
            }
        }
    }

    return Plugin_Continue;
}

Action Announce_Streak(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if ((stats_class & STATCLASS_STREAK) && stats.current_streak > 1) {
        for (int c = 0; c < sound_set.kill_streaks.Length; c++) {
            KillStreakConfig kill_streak;
            sound_set.kill_streaks.GetArray(c, kill_streak, sizeof(kill_streak));
            if (kill_streak.kills_req == stats.current_streak) {
                if (stats.current_streak > 4) {
                    GFLDM_PrintToChat(client, "%t", "Kill Streak", attacker, stats.current_streak);
                }
                if (ShouldAnnounce(client, attacker, victims, victim_count, kill_streak.sound_config)) {
                    GFLDM_EmitSound(client, kill_streak.sound_config.sound_file);
                    return Plugin_Stop;
                }
            }
        }
    }

    return Plugin_Continue;
}

Action Announce_Headshot(int client, SoundSet sound_set, int stats_class, PlayerStats stats, int attacker, int[] victims, int victim_count) {
    if (stats_class & STATCLASS_HEADSHOTS) {
        if (ShouldAnnounce(client, attacker, victims, victim_count, sound_set.headshot)) {
            GFLDM_EmitSound(client, sound_set.headshot.sound_file);
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

bool ShouldAnnounce(int client, int attacker, int[] victims, int victim_count, SoundConfig config) {
    if (
        (
            config.announce == AnnounceAll
            || (config.announce == AnnounceParticipants && (client == attacker || IsClientVictim(client, victims, victim_count)))
            || (config.announce == AnnounceVictim && IsClientVictim(client, victims, victim_count))
            || (config.announce == AnnounceAttacker && client == attacker)
        )
        && GFLDM_IsValidClient(attacker, true) && quake_enabled[client]
    ) {
        return true;
    }
    return false;
}

void PlayAnim_Collat(int client, int[] victims, int victim_count) {
    GFLDMAnimation anim = GFLDM_StartAnimOne(client);
    for (int i = 0, j = 1; j < victim_count; i++, j++) {
        float start[3], end[3];
        if (!GFLDM_IsValidClient(victims[i], true) || !GFLDM_IsValidClient(victims[j], true)) {
            continue;
        }

        GetClientAbsOrigin(victims[j], end);
        GetClientAbsOrigin(victims[i], start);
        start[2] = start[2] - 35.0;
        end[2] = end[2] - 35.0;
        anim.AddLightning(start, end, 0.08);
    }

    if (GFLDM_IsValidClient(victims[victim_count - 1], true)) {
        float start[3], end[3];
        GetClientAbsOrigin(victims[victim_count - 1], end);

        end[2] = end[2] - 35.0;
        GetLightningStart(end, start);
        anim.AddLightning(start, end);
        anim.AddExplosion(end);
        anim.AddAmbientSound(end, THUNDER_STRIKE_ROLLING, _, SNDLEVEL_GUNFIRE);
    }
    anim.Play();
}

void PlayAnim_ScoutElite(int attacker) {
    GFLDMAnimation anim = GFLDM_StartAnimAll();
    for (int c = 0; c < player_chain_states[attacker].rapid_scout_osok.stat_count; c++) {
        float origin[3];
        origin[0] = player_chain_states[attacker].rapid_scout_osok.victim_pos_x[c];
        origin[1] = player_chain_states[attacker].rapid_scout_osok.victim_pos_y[c];
        origin[2] = player_chain_states[attacker].rapid_scout_osok.victim_pos_z[c] - 59.0;

        float delay = float(c) * 0.075;
        anim.AddExplosion(origin, delay);

        delay = (float(c) * 0.125) + 1.0;
        float start[3];
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
        anim.AddExplosion(origin, delay);
        anim.AddAmbientSound(origin, THUNDER_STRIKE_ROLLING, delay, SNDLEVEL_GUNFIRE);
        anim.AddTesla(origin, 5.0, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
    }

    anim.Play();
}

void PlayAnim_AWPElite(int attacker) {
    GFLDMAnimation anim = GFLDM_StartAnimAll();
    for (int c = 0; c < player_chain_states[attacker].rapid_awp_osok.stat_count; c++) {
        float origin[3], fire_origin[3];
        origin[0] = player_chain_states[attacker].rapid_awp_osok.victim_pos_x[c];
        origin[1] = player_chain_states[attacker].rapid_awp_osok.victim_pos_y[c];
        origin[2] = player_chain_states[attacker].rapid_awp_osok.victim_pos_z[c] - 59.0;
        fire_origin[0] = player_chain_states[attacker].rapid_awp_osok.victim_pos_x[c];
        fire_origin[1] = player_chain_states[attacker].rapid_awp_osok.victim_pos_y[c];
        fire_origin[2] = player_chain_states[attacker].rapid_awp_osok.victim_pos_z[c] + 65.0;

        float delay = float(c) * 0.125;
        float start[3];
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
        anim.AddExplosion(origin, delay);
        anim.AddAmbientSound(origin, THUNDER_STRIKE_ROLLING, delay, SNDLEVEL_GUNFIRE);
        anim.AddFire(fire_origin, 3.0, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
    }

    anim.Play();
}

void PlayAnim_ScoutAce(int attacker) {
    GFLDMAnimation anim = GFLDM_StartAnimAll();
    for (int c = 0; c < player_chain_states[attacker].scout_osok.stat_count; c++) {
        float origin[3];
        origin[0] = player_chain_states[attacker].scout_osok.victim_pos_x[c];
        origin[1] = player_chain_states[attacker].scout_osok.victim_pos_y[c];
        origin[2] = player_chain_states[attacker].scout_osok.victim_pos_z[c] - 59.0;

        float delay = float(c) * 0.075;
        anim.AddExplosion(origin, delay);

        delay = (float(c) * 0.125) + 1.0;
        float start[3];
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
        anim.AddExplosion(origin, delay);
        anim.AddAmbientSound(origin, THUNDER_STRIKE_ROLLING, delay, SNDLEVEL_GUNFIRE);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
    }

    anim.Play();
}

void PlayAnim_AWPAce(int attacker) {
    GFLDMAnimation anim = GFLDM_StartAnimAll();
    for (int c = 0; c < player_chain_states[attacker].awp_osok.stat_count; c++) {
        float origin[3];
        origin[0] = player_chain_states[attacker].awp_osok.victim_pos_x[c];
        origin[1] = player_chain_states[attacker].awp_osok.victim_pos_y[c];
        origin[2] = player_chain_states[attacker].awp_osok.victim_pos_z[c] - 65.0;

        float delay = float(c) * 0.125;
        float start[3];
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
        anim.AddExplosion(origin, delay);
        anim.AddAmbientSound(origin, THUNDER_STRIKE_ROLLING, delay, SNDLEVEL_GUNFIRE);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
    }

    anim.Play();
}


void PlayAnim_DeagSpree(int attacker) {
    GFLDMAnimation anim = GFLDM_StartAnimAll();
    for (int c = 0; c < player_chain_states[attacker].one_deag.stat_count; c++) {
        float origin[3], fire_origin[3];
        origin[0] = player_chain_states[attacker].one_deag.victim_pos_x[c];
        origin[1] = player_chain_states[attacker].one_deag.victim_pos_y[c];
        origin[2] = player_chain_states[attacker].one_deag.victim_pos_z[c] - 65.0;
        fire_origin[0] = player_chain_states[attacker].one_deag.victim_pos_x[c];
        fire_origin[1] = player_chain_states[attacker].one_deag.victim_pos_y[c];
        fire_origin[2] = player_chain_states[attacker].one_deag.victim_pos_z[c] + 65.0;

        float delay = float(c) * 0.125;
        float start[3];
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
        anim.AddExplosion(origin, delay);
        anim.AddAmbientSound(origin, THUNDER_STRIKE_ROLLING, delay);
        anim.AddFire(fire_origin, 3.0, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);

        delay = delay + 0.25;
        GetLightningStart(origin, start);
        anim.AddLightning(start, origin, delay);
    }

    anim.Play();
}

void GetLightningStart(float end[3], float start[3]) {
    start[0] = end[0] + GetRandomFloat(-125.0, 125.0); 
    start[1] = end[1] + GetRandomFloat(-125.0, 125.0);
    start[2] = end[2] + 700.0;
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