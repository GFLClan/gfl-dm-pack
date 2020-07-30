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
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("GFLDM_PrintToChatAll", native_PrintToChatAll);
}

public int native_PrintToChatAll(Handle myself, int numParams) {
    char buffer[2048];

    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client)) {
            SetGlobalTransTarget(client);
            
            int out_written;
            FormatNativeString(0, 1, 2, sizeof(buffer), out_written, buffer, "");

            char replace_buffer[64];
            char color_buff[24];
            for (int c = 1; c < numParams; c++) {
                Format(replace_buffer, sizeof(replace_buffer), "{teamcolor[%d]}", c);
                if (StrContains(buffer, replace_buffer) != -1) {
                    GetTeamColor(GetNativeCellRef(c + 1), color_buff, sizeof(color_buff));
                    ReplaceString(buffer, sizeof(buffer), replace_buffer, color_buff);
                }
            }

            if (StrContains(buffer, "{normal}") != -1) {
                Color_Normal(color_buff, sizeof(color_buff));
                ReplaceString(buffer, sizeof(buffer), "{normal}", color_buff);
            }

            if (StrContains(buffer, "{green}") != -1) {
                Color_Green(color_buff, sizeof(color_buff));
                ReplaceString(buffer, sizeof(buffer), "{green}", color_buff);
            }

            PrintToChat(client, buffer);
        }
    }
}

stock void GetTeamColor(int client, char[] color_buff, int maxsize) {
    if (!(0 < client < MaxClients) || !IsClientInGame(client)) {
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