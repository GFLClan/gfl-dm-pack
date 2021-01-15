#include <sourcemod>
#include <websocket>
#include <gfldm>
#include <gfldm-web>
#include <gfldm-chat>

public Plugin myinfo = {
    name = "GFLDM Tags",
    author = "Dreae",
    description = "Custom chat tags",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

GFLDMWebApi api = null;

enum ColorType {
    ColorType_None = 0,
    ColorType_Solid,
    ColorType_Pattern
}

enum struct PlayerTagConfig {
    char tag[32];
    ColorType tag_type;
    char tag_pattern[128];
    char tag_color[32];

    ColorType name_type;
    char name_pattern[128];
    char name_color[32];

    ColorType chat_type;
    char chat_pattern[128];
    char chat_color[32];
}

PlayerTagConfig player_configs[MAXPLAYERS + 1];

public void OnPluginStart() {
    RegConsoleCmd("sm_namecolor", ConCmd_NameColor, "Set your name color in hexidecimal format, i.e ff22e2");
    RegConsoleCmd("sm_tagcolor", ConCmd_TagColor, "Set your tag color in hexidecimal format, i.e ff22e2");
    RegConsoleCmd("sm_resettag", ConCmd_ResetTag, "Reset your tag customizations");
    api = new GFLDMWebApi("ws://localhost:4000/api/servers/socket/websocket", "api_key", "tags:1");
    api.SetConnectCallback(Callback_ChannelConnected);
    LoadTranslations("gfldm_tags.phrases");
}

public Action ConCmd_ResetTag(int client, int args) {
    char steam_id[32];
    if (!GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id))) {
        return Plugin_Handled;
    }
    JSON payload = new JSON();
    payload.SetString("steamid", steam_id);
    api.Call("reset_tag", payload, Callback_ResetTag, client);
    delete payload;

    return Plugin_Handled;
}

public Action ConCmd_NameColor(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    if (args < 1) {
        Usage_NameColor(client);
        return Plugin_Handled;
    }

    char color[7];
    GetCmdArg(1, color, sizeof(color));
    if (strlen(color) != 6) {
        Usage_NameColor(client);
        return Plugin_Handled;
    }
    char steam_id[32];
    if (!GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id))) {
        return Plugin_Handled;
    }

    JSON payload = new JSON();
    payload.SetString("steamid", steam_id);
    payload.SetString("name_color", color);
    api.Call("set_name_color", payload, Callback_SetNameColor, client);
    delete payload;

    return Plugin_Handled;
}

public Action ConCmd_TagColor(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    if (args < 1) {
        Usage_TagColor(client);
        return Plugin_Handled;
    }

    char color[7];
    GetCmdArg(1, color, sizeof(color));
    if (strlen(color) != 6) {
        Usage_TagColor(client);
        return Plugin_Handled;
    }
    char steam_id[32];
    if (!GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id))) {
        return Plugin_Handled;
    }

    JSON payload = new JSON();
    payload.SetString("steamid", steam_id);
    payload.SetString("tag_color", color);
    api.Call("set_tag_color", payload, Callback_SetTagColor, client);
    delete payload;

    return Plugin_Handled;
}

void Usage_NameColor(int client) {
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
        ReplyToCommand(client, "\"!namecolor <color>\" - i.e. \x07ff22e2 ff22e2");
    } else {
        ReplyToCommand(client, "\"sm_namecolor <color>\" - i.e ff22e2");
    }
}

void Usage_TagColor(int client) {
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
        ReplyToCommand(client, "\"!tagcolor <color>\" - i.e. \x07ff22e2 ff22e2");
    } else {
        ReplyToCommand(client, "\"sm_tagcolor <color>\" - i.e ff22e2");
    }
}

public void Callback_ResetTag(GFLDMWebApi _api, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {
        GFLDM_PrintToChat(client, "%t", "Reset Tag");
        PrintToConsole(client, "%t", "Reset Tag Console");
        Callback_TagsLoaded(_api, response, data);
    }
}

public void Callback_SetNameColor(GFLDMWebApi _api, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {

        response.GetString("name_color", player_configs[client].name_color, sizeof(player_configs[].name_color));
        if (player_configs[client].name_type == ColorType_None) {
            player_configs[client].name_type = ColorType_Solid;
        }

        GFLDM_PrintToChat(client, "%t", "Set Name Color", player_configs[client].name_color);
        PrintToConsole(client, "%t", "Set Name Color Console", player_configs[client].name_color);
    }
}

public void Callback_SetTagColor(GFLDMWebApi _api, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {

        response.GetString("tag_color", player_configs[client].tag_color, sizeof(player_configs[].tag_color));
        if (player_configs[client].tag_type == ColorType_None) {
            player_configs[client].tag_type = ColorType_Solid;
        }

        GFLDM_PrintToChat(client, "%t", "Set Tag Color", player_configs[client].tag_color);
        PrintToConsole(client, "%t", "Set Tag Color Console", player_configs[client].tag_color);
    }
}

public void OnClientDisconnect(int client) {
    PlayerTagConfig zero;
    player_configs[client] = zero;
}

void InitClientState() {
    for (int c = 1; c <= MaxClients; c++) {
        if (GFLDM_IsValidClient(c) && IsClientAuthorized(c)) {
            char auth_string[32];
            if (GetClientAuthId(c, AuthId_Steam2, auth_string, sizeof(auth_string))) {
                OnClientAuthorized(c, auth_string); 
            }
        }
    }
}

public void OnClientAuthorized(int client, const char[] auth) {
    char auth_string[32];
    if (!IsFakeClient(client) && GetClientAuthId(client, AuthId_Steam3, auth_string, sizeof(auth_string))) {
        JSON payload = new JSON();
        payload.SetString("steamid", auth_string);
        api.Call("load_tags", payload, Callback_TagsLoaded, client);
    }
}

public void Callback_ChannelConnected(GFLDMWebApi _api, any data) {
    LogMessage("GFLDM API connected");
    InitClientState();
}

public void Callback_TagsLoaded(GFLDMWebApi _api, JSON response, any data) {
    int client = data;
    if (!IsFakeClient(client)) {
        PlayerTagConfig config;
        response.GetString("tag", config.tag, sizeof(config.tag));
        if (CanCustomizeTag(client)) {
            response.GetString("tag_color", config.tag_color, sizeof(config.tag_color));
        }
        if (strlen(config.tag_color) == 0) {
            response.GetString("default_tag_color", config.tag_color, sizeof(config.tag_color));
        }

        if (CanCustomizeTag(client)) {
            response.GetString("name_color", config.name_color, sizeof(config.name_color));
        }
        if (strlen(config.name_color) == 0) {
            response.GetString("default_name_color", config.name_color, sizeof(config.name_color));
        }

        if (CanCustomizeTag(client)) {
            response.GetString("chat_color", config.chat_color, sizeof(config.chat_color));
        }
        if (strlen(config.chat_color) == 0) {
            response.GetString("default_chat_color", config.chat_color, sizeof(config.chat_color));
        }

        if (CanCustomizeTag(client)) {
            response.GetString("tag_pattern", config.tag_pattern, sizeof(config.tag_pattern));
        }
        if (strlen(config.tag_pattern) == 0) {
            response.GetString("default_tag_pattern", config.tag_pattern, sizeof(config.tag_pattern));
        }

        if (strlen(config.tag) > 0) {
            if (strlen(config.tag_pattern) > 0) {
                config.tag_type = ColorType_Pattern;
            } else if (strlen(config.tag_color) > 0) {
                config.tag_type = ColorType_Solid;
            }
        }

        if (strlen(config.name_color) > 0) {
            config.name_type = ColorType_Solid;
        }

        player_configs[client] = config;
    }
}

bool CanCustomizeTag(int client) {
    return true;
}

public Action GFLDM_OnChatMessage(int author, char[] name, int name_max, char[] msg_body, int body_max) {
    if (player_configs[author].name_type == ColorType_Solid) {
        Format(name, name_max, "\x07%s%s", player_configs[author].name_color, name);
    } else if (player_configs[author].name_type == ColorType_Pattern) {
        Colorize(name, name_max, player_configs[author].name_pattern, name);
    } else {
        Format(name, name_max, "{teamcolor[1]}%s", name);
    }

    if (player_configs[author].chat_type == ColorType_Solid) {
        Format(msg_body, body_max, "\x07%s%s", player_configs[author].chat_color, msg_body);
    } else if (player_configs[author].chat_type == ColorType_Pattern) {
        Colorize(msg_body, body_max, player_configs[author].chat_pattern, msg_body);
    }

    if (strlen(player_configs[author].tag) > 0) {
        if (player_configs[author].tag_type == ColorType_Solid) {
            Format(name, name_max, "\x07%s%s %s", player_configs[author].tag_color, player_configs[author].tag, name);
        } else if (player_configs[author].tag_type == ColorType_Pattern) {
            char tag_buffer[128];
            Colorize(tag_buffer, sizeof(tag_buffer), player_configs[author].tag_pattern, player_configs[author].tag);
            Format(name, name_max, "%s %s", tag_buffer, name);
        } else {
            Format(name, name_max, "{normal}%s %s", player_configs[author].tag, name);
        }
    }

    return Plugin_Continue;
}

void Colorize(char[] buffer, int max_len, const char[] pattern, const char[] str) {
    char pattern_buffers[12][12];
    int pattern_len = ExplodeString(pattern, ";", pattern_buffers, 12, 12);
    if (pattern_len < 1) {
        return;
    }

    int src_len = strlen(str);
    int part_size = RoundToCeil(float(src_len) / float(pattern_len));
    char buffers[24][128];
    int toal_buffers = pattern_len * 2;
    int total_copied = 0;
    int j = 0;
    for (int c = 0; c < toal_buffers; c += 2) {
        if (total_copied >= src_len) {
            break;
        }

        Format(buffers[c], 128, "\x07%s", pattern_buffers[j]);
        j++;
        if (total_copied + part_size > src_len) {
            part_size = src_len - total_copied;
        }

        for (int i = 0; i < part_size; i++) {
            buffers[c + 1][i] = str[total_copied + i];
        }
        buffers[c + 1][part_size] = '\0';
        total_copied += part_size;
    }

    ImplodeStrings(buffers, toal_buffers, "", buffer, max_len);
}