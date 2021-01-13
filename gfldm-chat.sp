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

bool is_protobuf = false;
GlobalForward forward_OnChatMessage;

public void OnPluginStart() {
    UserMsg SayText2 = GetUserMessageId("SayText2");

    if (SayText2 != INVALID_MESSAGE_ID) {
        HookUserMessage(SayText2, OnSayText2, true);
    } else {
        SetFailState("Unable to hook SayText2");
    }
    is_protobuf = CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
    forward_OnChatMessage = new GlobalForward("GFLDM_OnChatMessage", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell);

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
    int paramOffset = 2;
    GetNativeString(1, buffer, sizeof(buffer));
    if (StrEqual(buffer, "%t")) {
        paramOffset += 1;
    }

    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client)) {
            SetGlobalTransTarget(client);
            
            int out_written;
            FormatNativeString(0, 1, 2, sizeof(buffer), out_written, buffer, "");

            fmt_print(client, buffer, sizeof(buffer), numParams, paramOffset);
        }
    }
}

public int native_PrintToChatFilter(Handle caller, int numParams) {
    char buffer[2048];
    int paramOffset = 3;
    GetNativeString(2, buffer, sizeof(buffer));
    if (StrEqual(buffer, "%t")) {
        paramOffset += 1;
    }
    
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

            fmt_print(client, buffer, sizeof(buffer), numParams, paramOffset);
        }
    }
}

public int native_PrintToChat(Handle caller, int numParams) {
    int client = GetNativeCell(1);
    if ((0 < client <= MaxClients) && IsClientInGame(client)) {
        char buffer[2048];
        SetGlobalTransTarget(client);

        int out_written;
        int paramOffset = 3;
        GetNativeString(2, buffer, sizeof(buffer));
        if (StrEqual(buffer, "%t")) {
            paramOffset += 1;
        }
        FormatNativeString(0, 2, 3, sizeof(buffer), out_written, buffer, "");

        fmt_print(client, buffer, sizeof(buffer), numParams, paramOffset);
    }
}

void fmt_print(int client, char[] buffer, int maxsize, int numParams, int paramOffset) {
    char replace_buffer[64];
    char color_buff[24];
    for (int c = paramOffset; c < numParams + 1; c++) {
        Format(replace_buffer, sizeof(replace_buffer), "{teamcolor[%d]}", (c - paramOffset) + 1);
        if (StrContains(buffer, replace_buffer) != -1) {
            GetTeamColor(GetNativeCellRef(c), color_buff, sizeof(color_buff));
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
    ReplaceString(buffer, maxsize, "{x}", "\x07");

    GFLDM_UescapeStr(buffer, maxsize);
    PrintToChat(client, buffer);
}

public Action OnSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
    int author = is_protobuf ? PbReadInt(msg, "ent_idx") : BfReadByte(msg);
    if (!GFLDM_IsValidClient(author)) {
        return Plugin_Continue;
    }

    bool is_chat = is_protobuf ? PbReadBool(msg, "chat") : BfReadByte(msg);
    char msg_name[32];
    if (is_protobuf) {
        PbReadString(msg, "msg_name", msg_name, sizeof(msg_name));
    } else {
        BfReadString(msg, msg_name, sizeof(msg_name));
    }
    
    char name[128];
    if (is_protobuf) {
        PbReadString(msg, "params", name, sizeof(name));
    } else {
        BfReadString(msg, name, sizeof(name));
    }
    char msg_body[256];
    if (is_protobuf) {
        PbReadString(msg, "params", msg_body, sizeof(msg_body));
    } else {
        BfReadString(msg, msg_body, sizeof(msg_body));
    }
    GFLDM_EscapeStr(msg_body, sizeof(msg_body));

    Action result;
    Call_StartForward(forward_OnChatMessage);
    Call_PushCell(author);
    Call_PushStringEx(name, sizeof(name), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(sizeof(name));
    Call_PushStringEx(msg_body, sizeof(msg_body), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(sizeof(msg_body));
    Call_Finish(result);
    if (result < Plugin_Handled) {
        char buffer[512];
        Format(buffer, sizeof(buffer), "{teamcolor[1]}%s{normal}: %s", name, msg_body);
        ArrayList pack = new ArrayList(512);
        pack.Push(author);
        pack.PushArray(players, playersNum);
        pack.Push(playersNum);
        pack.PushString(buffer);
        RequestFrame(PrintMessage, pack);
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

void GFLDM_EscapeStr(char[] buffer, int maxsize) {
    ReplaceString(buffer, maxsize, "&", "&amp;");
    ReplaceString(buffer, maxsize, "{", "&lb;");
    ReplaceString(buffer, maxsize, "}", "&rb;");
}


void GFLDM_UescapeStr(char[] buffer, int maxsize) {
    ReplaceString(buffer, maxsize, "&amp;", "&");
    ReplaceString(buffer, maxsize, "&lb;", "{");
    ReplaceString(buffer, maxsize, "&rb;", "}");
}

public void PrintMessage(any data) {
    ArrayList pack = data;
    int author = pack.Get(0);
    int players_num = pack.Get(2);
    int players[MAXPLAYERS];
    pack.GetArray(1, players, players_num);
    char buffer[512];
    pack.GetString(3, buffer, sizeof(buffer));

    for (int c = 0; c < players_num; c++) {
        GFLDM_PrintToChat(players[c], buffer, author);
    }
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