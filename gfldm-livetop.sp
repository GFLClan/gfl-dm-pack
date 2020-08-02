#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <gfldm>
#include <gfldm-stats>
#include <gfldm-chat>

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

#define CHANNEL_TITLE 1
#define CHANNEL_BODY 2

typedef LineFunction = function bool (int client, char[] linebuff, int maxsize);
typedef SortFunction = function int(StatsEntry a, StatsEntry b);

enum ActiveDisplay {
    Display_Accuracy = 0,
    Display_Headshots = 1,
    Display_Noscopes = 2,
    Display_KDR = 3
};

StatsEntry mostAccurate[4];
StatsEntry mostHeadshots[4];
StatsEntry mostNoscopes[4];
StatsEntry highestKdr[4];
ActiveDisplay displayed = Display_Accuracy;
bool noscopesEnabled = false;
Cookie enabled_cookie;
bool livetop_enabled[MAXPLAYERS + 1] = {false, ...};


public OnPluginStart() {
    HookEvent("player_spawn", Event_PlayerSpawn);
    RegConsoleCmd("sm_livestats", Cmd_LiveStats);
    enabled_cookie = new Cookie("gfldm-livestats", "", CookieAccess_Protected);
    LoadTranslations("gfldm_livetop.phrases");

    CreateTimer(60.0, Timer_UpdateDisplay, 0, TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] err, int errmax) {
    if (!LibraryExists("gfldm-stats")) {
        Format(err, errmax, "GFLDM Stats is required");
        return APLRes_Failure;
    }
    noscopesEnabled = LibraryExists("gfldm-noscopes");
    if (late) {
        for (int c = 1; c <= MaxClients; c++) {

        }
    }

    return APLRes_Success;
}

public void OnClientCookiesCached(client) {
    if (enabled_cookie.GetClientTime(client) == 0) {
        enabled_cookie.Set(client, "on");
        livetop_enabled[client] = true;
    } else {
        char buffer[10];
        enabled_cookie.Get(client, buffer, sizeof(buffer));

        livetop_enabled[client] = StrEqual(buffer, "on", false);
    }
}

public void OnClientDisconnect(int client) {
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
        ShowHudText(client, CHANNEL_TITLE, "");
        ShowHudText(client, CHANNEL_BODY, "");
    }

    return Plugin_Handled;
}

Action Timer_UpdateDisplay(Handle timer) {
    displayed = (displayed + 1) % 4;
    if (displayed == Display_Noscopes && !noscopesEnabled) {
        displayed = Display_KDR;
    }
    RedrawAll();
    
    return Plugin_Continue;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GFLDM_IsValidClient(client)) {
        RedrawClient(client);
    }
}

void Draw(int client, const char[] title, LineFunction line_fn) {
    ShowHudText(client, CHANNEL_TITLE, "");
    ShowHudText(client, CHANNEL_BODY, "");
    ShowHudText(client, CHANNEL_TITLE, "");
    ShowHudText(client, CHANNEL_BODY, "");

    SetHudTextParams(0.14, 0.03, 600.0, 0, 118, 178, 255);
    ShowHudText(client, CHANNEL_TITLE, "%t", title);
    
    char buffer[512];
    RenderBody(buffer, sizeof(buffer), line_fn);

    SetHudTextParams(0.14, 0.06, 600.0, 164, 178, 149, 255);
    ShowHudText(client, CHANNEL_BODY, buffer);
}

void RedrawClient(int client) {
    if(livetop_enabled[client] && GFLDM_IsValidClient(client)) {
        switch (displayed) {
            case Display_Accuracy:
                Draw(client, "Highest Accuracy", RenderLine_Accuracy);
            case Display_Headshots:
                Draw(client, "Most Headshots", RenderLine_Headshots);
            case Display_Noscopes: 
                Draw(client, "Most Noscopes", RenderLine_Noscopes);
            case Display_KDR:
                Draw(client, "Highest KDR", RenderLine_KDR);
        }
    }
}

void RedrawAll() {
    for (int c = 0; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c)) {
            RedrawClient(c);
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
    ReplaceString(buffer, maxsize, "{pct_tkn}", "%%");
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

public void GFLDM_OnStatsUpdate(int client, int stats_class, PlayerStats stats) {
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

    if (stats_class & STATCLASS_HEADSHOTS != 0) {
        update_top(mostHeadshots, sizeof(mostHeadshots), new_entry, sort_HSPercent);
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

