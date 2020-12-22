#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <gfldm>
#include <gfldm-chat>

public Plugin myinfo = {
    name = "GFLDM Chat",
    author = "Dreae",
    description = "Chat helpers",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

public void OnPluginStart() {
    GFLDM_DefineVersion("gfldm_chat_version");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("GFLDM_PrintToChatAll", native_PrintToChatAll);
    CreateNative("GFLDM_PrintToChatFilter", native_PrintToChatFilter);
    CreateNative("GFLDM_PrintToChat", native_PrintToChat);
    RegPluginLibrary("gfldm-chat");
}

public int native_PrintToChatAll(Handle caller, int numParams) {
    char buffer[2048];

    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client)) {
            SetGlobalTransTarget(client);
            
            int out_written;
            FormatNativeString(0, 1, 2, sizeof(buffer), out_written, buffer, "");

            fmt_print(client, buffer, sizeof(buffer), numParams, 1);
        }
    }
}

public int native_PrintToChatFilter(Handle caller, int numParams) {
    char buffer[2048];
    
    bool filter_res = false;
    Function filter_func = GetNativeFunction(1);

    for (int client = 1; client <= MaxClients; client++) {
        Call_StartFunction(caller, filter_func);
        Call_PushCell(client);
        int call_res = Call_Finish(filter_res);

        if (IsClientInGame(client) && call_res == SP_ERROR_NONE && filter_res) {
            SetGlobalTransTarget(client);
            
            int out_written;
            FormatNativeString(0, 2, 3, sizeof(buffer), out_written, buffer, "");

            fmt_print(client, buffer, sizeof(buffer), numParams, 2);
        }
    }
}

public int native_PrintToChat(Handle caller, int numParams) {
    int client = GetNativeCell(1);
    if ((0 < client <= MaxClients) && IsClientInGame(client)) {
        char buffer[2048];
        SetGlobalTransTarget(client);

        int out_written;
        FormatNativeString(0, 2, 3, sizeof(buffer), out_written, buffer, "");

        fmt_print(client, buffer, sizeof(buffer), numParams, 1);
    }
}

void fmt_print(int client, char[] buffer, int maxsize, int numParams, int paramOffset) {
    char replace_buffer[64];
    char color_buff[24];
    for (int c = 1; c < numParams; c++) {
        Format(replace_buffer, sizeof(replace_buffer), "{teamcolor[%d]}", c);
        if (StrContains(buffer, replace_buffer) != -1) {
            GetTeamColor(GetNativeCellRef(c + paramOffset), color_buff, sizeof(color_buff));
            ReplaceString(buffer, maxsize, replace_buffer, color_buff);
        }
    }

    if (StrContains(buffer, "{normal}") != -1) {
        Color_Normal(color_buff, sizeof(color_buff));
        ReplaceString(buffer, maxsize, "{normal}", color_buff);
    }

    if (StrContains(buffer, "{green}") != -1) {
        Color_Green(color_buff, sizeof(color_buff));
        ReplaceString(buffer, maxsize, "{green}", color_buff);
    }

    if (StrContains(buffer, "{team_ct}") != -1) {
        Color_CT(color_buff, sizeof(color_buff));
        ReplaceString(buffer, maxsize, "{team_ct}", color_buff);
    }


    if (StrContains(buffer, "{team_t}") != -1) {
        Color_CT(color_buff, sizeof(color_buff));
        ReplaceString(buffer, maxsize, "{team_t}", color_buff);
    }

    PrintToChat(client, buffer);
}

stock void GetTeamColor(int client, char[] color_buff, int maxsize) {
    if (!(0 < client <= MaxClients) || !IsClientInGame(client)) {
        ThrowError("Invalid client index %i", client);
    }

    switch (GetClientTeam(client)) {
        case CS_TEAM_SPECTATOR:
            Color_Spec(color_buff, maxsize);
        case CS_TEAM_NONE:
            Color_Spec(color_buff, maxsize);
        case CS_TEAM_T:
            Color_T(color_buff, maxsize);
        case CS_TEAM_CT:
            Color_CT(color_buff, maxsize);
    }
}

// TODO: Update these to support CS:GO as well
stock void Color_Spec(char[] color_buff, int maxsize) {
    strcopy(color_buff, maxsize, "\x07CCCCCC");
}

stock void Color_T(char[] color_buff, int maxsize) {
    strcopy(color_buff, maxsize, "\x07FF4040");
}

stock void Color_CT(char[] color_buff, int maxsize) {
    strcopy(color_buff, maxsize, "\x0799CCFF");
}

stock void Color_Green(char[] color_buff, int maxsize) {
    strcopy(color_buff, maxsize, "\x073EFF3E");
}

stock void Color_Normal(char[] color_buff, int maxsize) {
    strcopy(color_buff, maxsize, "\x01");
}