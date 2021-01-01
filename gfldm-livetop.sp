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
#include <gfldm>
#include <gfldm-chat>
#include <gfldm-anim>
#include <gfldm-stats>
#include <gfldm-clientprefs>

public Plugin myinfo = {
    name = "GFLDM Live Top",
    author = "Dreae",
    description = "Shows top player session statistics",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

enum struct StatsEntry {
    int client;
    PlayerStats stats;
}

enum struct HudElements {
    GFLDMHudElement title;
    GFLDMHudElement body;
    float last_draw;
}

typedef LineFunction = function bool (int client, char[] linebuff, int maxsize);
typedef SortFunction = function int(StatsEntry a, StatsEntry b);

enum ActiveDisplay {
    Display_Accuracy = 0,
    Display_Headshots = 1,
    Display_Noscopes = 2,
    Display_KDR = 3,
    Display_Streak = 4
};

#define SZ_STATS 5

StatsEntry mostAccurate[SZ_STATS];
StatsEntry mostHeadshots[SZ_STATS];
StatsEntry mostNoscopes[SZ_STATS];
StatsEntry highestKdr[SZ_STATS];
StatsEntry highestStreak[SZ_STATS];
ActiveDisplay displayed = Display_Accuracy;
bool noscopesEnabled = false;
Cookie enabled_cookie;
bool livetop_enabled[MAXPLAYERS + 1] = {false, ...};
HudElements hud_elements[MAXPLAYERS + 1];
ConVar cvar_cycle_time;
Handle timer_cycle;


public OnPluginStart() {
    GFLDM_DefineVersion("gfldm_livestats_version");

    HookEvent("player_spawn", Event_PlayerSpawn);
    RegConsoleCmd("sm_livestats", Cmd_LiveStats);

    enabled_cookie = new Cookie("gfldm-livestats", "", CookieAccess_Protected);
    FIRE_CLIENT_COOKIES()
    LoadTranslations("gfldm_livetop.phrases");
    cvar_cycle_time = CreateConVar("gfldm_livestats_cycle_time", "60.0", "Cycle time in seconds");
    cvar_cycle_time.AddChangeHook(CvarChanged);

    AutoExecConfig();
    
    for (int c = 1; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c)) {
            OnClientConnected(c);
        }
    }
}

public void OnConfigsExecuted() {
    if (timer_cycle == null) {
        timer_cycle = CreateTimer(cvar_cycle_time.FloatValue, Timer_UpdateDisplay, 0, TIMER_REPEAT);
    }
}

public void CvarChanged(ConVar cvar, const char[] oldVlue, const char[] newValue) {
    if (timer_cycle != null) {
        KillTimer(timer_cycle);
    }

    timer_cycle = CreateTimer(cvar_cycle_time.FloatValue, Timer_UpdateDisplay, 0, TIMER_REPEAT);
}

public void OnAllPluginsLoaded() {
    GFLDM_RequireLibrary("gfldm-stats");
    GFLDM_RequireLibrary("gfldm-anim");
    noscopesEnabled = LibraryExists("gfldm-noscopes");
}

LOAD_COOKIE_BOOL(enabled_cookie, livetop_enabled, "on", true)

public void OnClientConnected(int client) {
    GFLDMHudElement title = new GFLDMHudElement(client, 0.14, 0.03);
    GFLDMHudElement body = new GFLDMHudElement(client, 0.14, 0.06);
    
    int color[4] = {0, 118, 178, 255};
    title.SetColor(color);
    color = {164, 178, 149, 255};
    body.SetColor(color);

    hud_elements[client].title = title;
    hud_elements[client].body = body;
}

public void OnClientDisconnect(int client) {
    hud_elements[client].title.CloseTrie();
    hud_elements[client].body.CloseTrie();
    hud_elements[client].last_draw = 0.0;
    hud_elements[client].title = null;
    hud_elements[client].body = null;
    
    for (int c = 0; c < sizeof(mostAccurate); c++) {
        StatsEntry zero;
        if (mostAccurate[c].client == client) {
            mostAccurate[c] = zero;
        }
        
        if (mostHeadshots[c].client == client) {
            mostHeadshots[c] = zero;
        }
        
        if (mostNoscopes[c].client == client) {
            mostNoscopes[c] = zero;
        }
        
        if (highestKdr[c].client == client) {
            highestKdr[c] = zero;
        }
    }
}

public Action Cmd_LiveStats(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    livetop_enabled[client] = !livetop_enabled[client];
    if (livetop_enabled[client]) {
        enabled_cookie.Set(client, "on");
        GFLDM_PrintToChat(client, "%t", "Livestats enabled");
        RedrawClient(client);
    } else {
        enabled_cookie.Set(client, "off");
        GFLDM_PrintToChat(client, "%t", "Livestats disabled");
        hud_elements[client].title.Clear();
        hud_elements[client].body.Clear();
    }

    return Plugin_Handled;
}

Action Timer_UpdateDisplay(Handle timer) {
    displayed = (displayed + 1) % (Display_Streak + 1);
    if (displayed == Display_Noscopes && !noscopesEnabled) {
        displayed = Display_KDR;
    }
    RedrawAll(true);
    
    return Plugin_Continue;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GFLDM_IsValidClient(client)) {
        RedrawClient(client, true);
    }
}

void Draw(int client, const char[] title, LineFunction line_fn, bool force=false) {
    float time = GetGameTime();
    if (time - hud_elements[client].last_draw >= 1.0 || force) {
        hud_elements[client].title.Draw(600.0, "%t", title);

        char buffer[512];
        RenderBody(buffer, sizeof(buffer), line_fn);
        hud_elements[client].body.Draw(600.0, buffer);

        hud_elements[client].last_draw = time;
    }
}

void RedrawClient(int client, bool force=false) {
    if(livetop_enabled[client] && GFLDM_IsValidClient(client)) {
        switch (displayed) {
            case Display_Accuracy:
                Draw(client, "Highest Accuracy", RenderLine_Accuracy, force);
            case Display_Headshots:
                Draw(client, "Most Headshots", RenderLine_Headshots, force);
            case Display_Noscopes: 
                Draw(client, "Most Noscopes", RenderLine_Noscopes, force);
            case Display_KDR:
                Draw(client, "Highest KDR", RenderLine_KDR, force);
            case Display_Streak:
                Draw(client, "Highest Streak", RenderLine_Streak, force);
        }
    }
}

void RedrawAll(bool force=false) {
    for (int c = 0; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c)) {
            RedrawClient(c, force);
        }
    }
}

void RenderBody(char[] buffer, int maxsize, LineFunction line_fn) {
    char lines[3][256];
    int i = 0;
    for  (int c = 0; c < 3; c++) {
        int res;
        Call_StartFunction(INVALID_HANDLE, line_fn);
        Call_PushCell(c);
        Call_PushStringEx(lines[i], sizeof(lines[]), SM_PARAM_STRING_BINARY, SM_PARAM_COPYBACK);
        Call_PushCell(sizeof(lines[]));
        Call_Finish(res);
        if (res) {
            i++;
        }
    }

    ImplodeStrings(lines, i, "\n", buffer, maxsize);
    // Format functions act real weird with percent signs
    ReplaceString(buffer, maxsize, "{pct_tkn}", "%%%%");
}

bool RenderLine_Accuracy(int j, char[] line, int maxsize) {
    if (GFLDM_IsValidClient(mostAccurate[j].client, true)) {
        Format(line, maxsize, " %N: %.1f{pct_tkn}", mostAccurate[j].client, Accuracy(mostAccurate[j].stats) * 100.0);
        return true;
    }

    return false;
}

bool RenderLine_Headshots(int j, char[] line, int maxsize) {
    if (GFLDM_IsValidClient(mostHeadshots[j].client, true)) {
        Format(line, maxsize, " %N: %.1f{pct_tkn}", mostHeadshots[j].client, HSPercent(mostHeadshots[j].stats) * 100.0);
        return true;
    }

    return false;
}

bool RenderLine_Noscopes(int j, char[] line, int maxsize) {
    if (GFLDM_IsValidClient(mostNoscopes[j].client, true)) {
        Format(line, maxsize, " %N: %d", mostNoscopes[j].client, mostNoscopes[j].stats.noscopes);
        return true;
    }

    return false;
}

bool RenderLine_KDR(int j, char[] line, int maxsize) {
    if (GFLDM_IsValidClient(highestKdr[j].client, true)) {
        Format(line, maxsize, " %N: %.2f", highestKdr[j].client, KDR(highestKdr[j].stats));
        return true;
    }

    return false;
}

bool RenderLine_Streak(int j, char[] line, int maxsize) {
    if (GFLDM_IsValidClient(highestStreak[j].client, true)) {
        Format(line, maxsize, " %N: %d", highestStreak[j].client, highestStreak[j].stats.highest_streak);
        return true;
    }

    return false;
}

bool RenderLine_OneDeag(int j, char[] line, int maxsize) {
    if (GFLDM_IsValidClient(highestStreak[j].client, true)) {
        Format(line, maxsize, " %N: %d", highestStreak[j].client, highestStreak[j].stats.one_deags);
        return true;
    }

    return false;
}

public void GFLDM_OnStatsUpdate(int client, int stats_class, PlayerStats stats, int[] victims, int victim_count) {
    StatsEntry new_entry;
    new_entry.client = client;
    new_entry.stats = stats;
    bool redraw = false;

    if (stats_class & STATCLASS_NOSCOPES != 0) {
        update_top(mostNoscopes, sizeof(mostNoscopes), new_entry, sort_Noscopes);
        redraw = true;
    }

    if (stats_class & STATCLASS_KDR != 0) {
        update_top(highestKdr, sizeof(highestKdr), new_entry, sort_KDR);
        redraw = true;
    }

    if (stats_class & STATCLASS_ACCURACY != 0) {
        update_top(mostAccurate, sizeof(mostAccurate), new_entry, sort_Accuracy);
        redraw = true;
    }

    if (stats_class & STATCLASS_HEADSHOTS != 0 || stats_class & STATCLASS_KILLS != 0) {
        update_top(mostHeadshots, sizeof(mostHeadshots), new_entry, sort_HSPercent);
        redraw = true;
    }

    if (stats_class & STATCLASS_HIGHEST_STREAK != 0) {
        update_top(highestStreak, sizeof(highestStreak), new_entry, sort_Streak);
        redraw = true;
    }

    if (redraw) {
        RedrawAll();
    }
}

int sort_Noscopes(StatsEntry a, StatsEntry b) {
    return a.stats.noscopes - b.stats.noscopes;
}

float KDR(PlayerStats stats) {
    if (stats.deaths == 0) {
        return float(stats.kills);
    }

    return float(stats.kills) / float(stats.deaths);
}


int sort_KDR(StatsEntry a, StatsEntry b) {
    float a_kdr = KDR(a.stats);
    float b_kdr = KDR(b.stats);
    if (a_kdr > b_kdr) {
        return 1;
    } else if (a_kdr < b_kdr) {
        return -1;
    }

    return 0;
}

float Accuracy(PlayerStats stats) {
    if (stats.hits == 0) {
        return 0.0;
    }

    return float(stats.hits) / float(stats.shots);
}

int sort_Accuracy(StatsEntry a, StatsEntry b) {
    float a_accuracy = Accuracy(a.stats);
    float b_accuracy = Accuracy(b.stats);
    if (a_accuracy > b_accuracy) {
        return 1;
    } else if (a_accuracy < b_accuracy) {
        return -1;
    }

    return 0;
}

float HSPercent(PlayerStats stats) {
    if (stats.kills == 0) {
        return 0.0;
    }

    return float(stats.headshots) / float(stats.kills);
}

int sort_HSPercent(StatsEntry a, StatsEntry b) {
    float a_hs = HSPercent(a.stats);
    float b_hs = HSPercent(b.stats);
    if (a_hs > b_hs) {
        return 1;
    } else if (a_hs < b_hs) {
        return -1;
    }

    return 0;
}

int sort_Streak(StatsEntry a, StatsEntry b) {
    return a.stats.highest_streak - b.stats.highest_streak;
}

void update_top(StatsEntry[] entries, int maxsize, StatsEntry new_entry, SortFunction comp_func) {
    for (int c = 0; c < maxsize; c++) {
        if (entries[c].client == new_entry.client) {
            entries[c] = new_entry;
            isort(entries, maxsize, comp_func);
            return;
        }
    }

    entries[maxsize - 1] = new_entry;
    isort(entries, maxsize, comp_func);
}

void isort(StatsEntry[] entries, int maxsize, SortFunction sort) {
    for (int c = 1; c < maxsize; c++) {
        int i = c;
        while (i > 0) {
            int res;
            Call_StartFunction(INVALID_HANDLE, sort);

            Call_PushArray(entries[i - 1], sizeof(entries[]));
            Call_PushArray(entries[i], sizeof(entries[]));
            Call_Finish(res);
            if (res > 0) {
                break;
            }
            
            StatsEntry a;
            a = entries[i];
            entries[i] = entries[i - 1];
            entries[i - 1] = a;

            i--;
        }
    }
}

