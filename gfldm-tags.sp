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

#define COLORTYPE_NONE    0
#define COLORTYPE_SOLID   (1<<1)
#define COLORTYPE_PATTERN (1<<2)
#define COLORTYPE_DEFAULT (1<<16)

enum struct PlayerTagConfig {
    char tag[32];
    int tag_type;
    char tag_pattern[128];
    char tag_color[32];

    int name_type;
    char name_pattern[128];
    char name_color[32];

    int chat_type;
    char chat_pattern[128];
    char chat_color[32];
}

PlayerTagConfig player_configs[MAXPLAYERS + 1];

ConVar cvar_server_id;
ConVar cvar_api_key;
ConVar cvar_websocket_url;
ConVar cvar_custom_tag_flags;
int custom_tag_flags_required;

public void OnPluginStart() {
    RegConsoleCmd("sm_namecolor", ConCmd_NameColor, "Set your name color in hexidecimal format, i.e ff22e2");
    RegConsoleCmd("sm_tagcolor", ConCmd_TagColor, "Set your tag color in hexidecimal format, i.e ff22e2");
    RegConsoleCmd("sm_chatcolor", ConCmd_ChatColor, "Set your chat color in hexidecimal format, i.e ff22e2");
    RegConsoleCmd("sm_resettag", ConCmd_ResetTag, "Reset your tag customizations");
    RegConsoleCmd("sm_disabletag", ConCmd_DisableTag, "Disable your tag");
    RegConsoleCmd("sm_tags", ConCmd_Tags, "Adjust tag settings");
    RegConsoleCmd("sm_tag", ConCmd_Tag, "Set your custom chat tag");

    cvar_server_id = CreateConVar("gfldm_tags_server_id", "-1", "Server ID for this server in GFLDM Web");
    cvar_api_key = CreateConVar("gfldm_tags_api_key", "apikey", "Server ID for this server in GFLDM Web");
    cvar_websocket_url = CreateConVar("gfldm_tags_websock_url", "ws://localhost:4000/api/servers/socket/websocket", "Tags websocket URL");
    cvar_server_id.AddChangeHook(ConnectionVarChanged);
    cvar_api_key.AddChangeHook(ConnectionVarChanged);
    cvar_websocket_url.AddChangeHook(ConnectionVarChanged);

    cvar_custom_tag_flags = CreateConVar("gfldm_tags_custom_flag", "s", "Flags required to customize tags");
    cvar_custom_tag_flags.AddChangeHook(Cvar_CustomFlagsChanged);
    AutoExecConfig();
    LoadTranslations("gfldm_tags.phrases");
}

public void OnConfigsExecuted() {
    Cvar_CustomFlagsChanged(cvar_custom_tag_flags, "", "");
    if (api == null) {
        int server_id = cvar_server_id.IntValue;
        if (server_id > 0) {
            char websocket_url[512];
            char api_key[256];
            char topic[64];
            Format(topic, sizeof(topic), "tags:%d", server_id);
            cvar_websocket_url.GetString(websocket_url, sizeof(websocket_url));
            cvar_api_key.GetString(api_key, sizeof(api_key));
            
            api = new GFLDMWebApi(websocket_url, api_key, topic);
            api.SetConnectCallback(Callback_ChannelConnected);
        }
    }
}

public void ConnectionVarChanged(ConVar cvar, const char[] old_value, const char[] new_value) {
    if (!StrEqual(old_value, new_value)) {
        if (api != null) {
            api.Close();
            api = null;
        }

        OnConfigsExecuted();
    }
}

public void Cvar_CustomFlagsChanged(ConVar cvar, const char[] old_value, const char[] new_value) {
    char flagString[64];
    cvar_custom_tag_flags.GetString(flagString, sizeof(flagString));
    custom_tag_flags_required = ReadFlagString(flagString);
}

public Action ConCmd_Tags(int client, int args) {
    if (!GFLDM_IsValidClient(client)) {
        return Plugin_Handled;
    }

    Menu menu = new Menu(Menu_Tags, MenuAction_DisplayItem);
    menu.AddItem("pick_tag", "Menu Change Tag");
    menu.AddItem("reset_tag", "Menu Reset Tag");
    menu.AddItem("disable_tag", "Menu Disable Tag");
    menu.SetTitle("!tags");
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
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


public Action ConCmd_DisableTag(int client, int args) {
    char steam_id[32];
    if (!GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id))) {
        return Plugin_Handled;
    }
    JSON payload = new JSON();
    payload.SetString("steamid", steam_id);
    api.Call("disable_tag", payload, Callback_DisableTag, client);
    delete payload;

    return Plugin_Handled;

}

public Action ConCmd_Tag(int client, int args) {
    if (!CanCustomizeTag(client)) {
        return Plugin_Handled;
    }

    if (args < 1) {
        Usage_Tag(client);
        return Plugin_Handled;
    }
    char steam_id[32];
    if (!GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id))) {
        return Plugin_Handled;
    }

    char buffer[128];
    GetCmdArgString(buffer, sizeof(buffer));
    JSON payload = new JSON();
    payload.SetString("steamid", steam_id);
    payload.SetString("custom_tag", buffer);
    api.Call("set_custom_tag", payload, Callback_CustomTag, client);

    return Plugin_Handled;
}

public Action ConCmd_NameColor(int client, int args) {
    if (!CanCustomizeTag(client)) {
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
    if (!CanCustomizeTag(client)) {
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

public Action ConCmd_ChatColor(int client, int args) {
    if (!CanCustomizeTag(client)) {
        return Plugin_Handled;
    }

    if (args < 1) {
        Usage_ChatColor(client);
        return Plugin_Handled;
    }

    char color[7];
    GetCmdArg(1, color, sizeof(color));
    if (strlen(color) != 6) {
        Usage_ChatColor(client);
        return Plugin_Handled;
    }
    char steam_id[32];
    if (!GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id))) {
        return Plugin_Handled;
    }

    JSON payload = new JSON();
    payload.SetString("steamid", steam_id);
    payload.SetString("chat_color", color);
    api.Call("set_chat_color", payload, Callback_SetChatColor, client);
    delete payload;

    return Plugin_Handled;
}

void Usage_Tag(int client) {
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
        ReplyToCommand(client, "[!tags] \"!tag <tag>\"");
    } else {
        ReplyToCommand(client, "\"sm_tag <tag>\"");
    }
}

void Usage_NameColor(int client) {
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
        ReplyToCommand(client, "[!tags] \"!namecolor <color>\"");
    } else {
        ReplyToCommand(client, "\"sm_namecolor <color>\" - i.e ff22e2");
    }
}

void Usage_TagColor(int client) {
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
        ReplyToCommand(client, "[!tags] \"!tagcolor <color>\"");
    } else {
        ReplyToCommand(client, "\"sm_tagcolor <color>\" - i.e ff22e2");
    }
}

void Usage_ChatColor(int client) {
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
        ReplyToCommand(client, "[!tags] \"!chatcolor <color>\"");
    } else {
        ReplyToCommand(client, "\"sm_chatcolor <color>\" - i.e ff22e2");
    }
}

public int Menu_Tags(Menu menu, MenuAction action, int param1, int param2) {
    int client = param1;
    if (action == MenuAction_Select) {
        if (!GFLDM_IsValidClient(client)) {
            return 0;
        }

        char info[32];
        if (menu.GetItem(param2, info, sizeof(info))) {
            char auth_id[32];
            if (!GetClientAuthId(client, AuthId_Steam3, auth_id, sizeof(auth_id))) {
                return 0;
            }

            if (StrEqual(info, "pick_tag")) {
                JSON payload = new JSON();
                int admin_flags = GFLDM_GetAdminFlags(client);
                payload.SetString("steamid", auth_id);
                payload.SetInt("admin_flags", admin_flags);
                api.Call("get_player_tags", payload, Callback_PickTag, client);
                delete payload;
            } else if (StrEqual(info, "disable_tag")) {
                JSON payload = new JSON();
                payload.SetString("steamid", auth_id);
                api.Call("disable_tag", payload, Callback_DisableTag, client);
                delete payload;
            } else if (StrEqual(info, "reset_tag")) {
                JSON payload = new JSON();
                payload.SetString("steamid", auth_id);
                api.Call("reset_tag", payload, Callback_ResetTag, client);
                delete payload;
            }
        }
    } else if (action == MenuAction_DisplayItem) {
        char display[64];
        menu.GetItem(param2, "", 0, _, display, sizeof(display));

        char buffer[255];
        Format(buffer, sizeof(buffer), "%T", display, param1);
        return RedrawMenuItem(buffer);
    } else if (action == MenuAction_End) {
        delete menu;
    }

    return 0;
}

public int Menu_PickTag(Menu menu, MenuAction action, int param1, int param2) {
    int client = param1;
    if (action == MenuAction_Select) {
        if (!GFLDM_IsValidClient(client)) {
            return;
        }

        char info[32];
        if (menu.GetItem(param2, info, sizeof(info))) {
            char auth_id[32];
            if (!GetClientAuthId(client, AuthId_Steam3, auth_id, sizeof(auth_id))) {
                return;
            }
            int tag_id = StringToInt(info);

            JSON payload = new JSON();
            payload.SetString("steamid", auth_id);
            payload.SetInt("tag_id", tag_id);
            api.Call("set_tag", payload, Callback_SetTag, client);
            delete payload;
        }
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

public void Callback_CustomTag(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {
        if (StrEqual(status, "ok")) {
            GFLDM_PrintToChat(client, "%t", "Tag Changed");
            PrintToConsole(client, "%t", "Tag Changed Console");
            response.GetString("custom_tag", player_configs[client].tag, sizeof(player_configs[].tag));
        } else {
            GFLDM_PrintToChat(client, "%t", "Invalid Tag");
        }
    }
}

public void Callback_SetTag(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {
        GFLDM_PrintToChat(client, "%t", "Tag Changed");
        PrintToConsole(client, "%t", "Tag Changed Console");
        Callback_TagsLoaded(_api, status, response, data);
    }
}

public void Callback_ResetTag(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {
        GFLDM_PrintToChat(client, "%t", "Reset Tag");
        PrintToConsole(client, "%t", "Reset Tag Console");
        Callback_TagsLoaded(_api, status, response, data);
    }
}

public void Callback_PickTag(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (!GFLDM_IsValidClient(client)) {
        return;
    }
    Menu menu = new Menu(Menu_PickTag);
    for (int c = 0; c < response.GetArraySize(); c++) {
        JSON tag = response.GetArrayJSON(c);
        char tag_name[32], tag_id[12];
        IntToString(tag.GetInt("tag_id"), tag_id, sizeof(tag_id));
        tag.GetString("tag", tag_name, sizeof(tag_name));
        menu.AddItem(tag_id, tag_name);
        delete tag;
    }
    menu.SetTitle("Pick a new tag");
    menu.Display(client, MENU_TIME_FOREVER);
}

public void Callback_DisableTag(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {
        GFLDM_PrintToChat(client, "%t", "Disable Tag");
        PrintToConsole(client, "%t", "Disable Tag Console");
        PlayerTagConfig zero;
        player_configs[client] = zero;
    }
}

public void Callback_SetNameColor(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {

        response.GetString("name_color", player_configs[client].name_color, sizeof(player_configs[].name_color));
        if (player_configs[client].name_type == COLORTYPE_NONE || player_configs[client].name_type & COLORTYPE_DEFAULT) {
            player_configs[client].name_type = COLORTYPE_SOLID;
        }

        GFLDM_PrintToChat(client, "%t", "Set Name Color", player_configs[client].name_color);
        PrintToConsole(client, "%t", "Set Name Color Console", player_configs[client].name_color);
    }
}

public void Callback_SetTagColor(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {

        response.GetString("tag_color", player_configs[client].tag_color, sizeof(player_configs[].tag_color));
        if (player_configs[client].tag_type == COLORTYPE_NONE || player_configs[client].tag_type & COLORTYPE_DEFAULT) {
            player_configs[client].tag_type = COLORTYPE_SOLID;
        }

        GFLDM_PrintToChat(client, "%t", "Set Tag Color", player_configs[client].tag_color);
        PrintToConsole(client, "%t", "Set Tag Color Console", player_configs[client].tag_color);
    }
}

public void Callback_SetChatColor(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (GFLDM_IsValidClient(client)) {

        response.GetString("chat_color", player_configs[client].chat_color, sizeof(player_configs[].chat_color));
        if (player_configs[client].chat_type == COLORTYPE_NONE || player_configs[client].chat_type & COLORTYPE_DEFAULT) {
            player_configs[client].chat_type = COLORTYPE_SOLID;
        }

        GFLDM_PrintToChat(client, "%t", "Set Chat Color", player_configs[client].chat_color);
        PrintToConsole(client, "%t", "Set Chat Color Console", player_configs[client].chat_color);
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

public void Callback_TagsLoaded(GFLDMWebApi _api, const char[] status, JSON response, any data) {
    int client = data;
    if (!IsFakeClient(client) && StrEqual(status, "ok")) {
        PlayerTagConfig config;
        
        if (CanCustomizeTag(client)) {
            response.GetString("custom_tag", config.tag, sizeof(config.tag));
        }
        if (strlen(config.tag) == 0) {
            response.GetString("tag", config.tag, sizeof(config.tag));
        }
        
        if (CanCustomizeTag(client)) {
            response.GetString("tag_color", config.tag_color, sizeof(config.tag_color));
        }
        if (strlen(config.tag_color) == 0) {
            response.GetString("default_tag_color", config.tag_color, sizeof(config.tag_color));
            config.tag_type = COLORTYPE_DEFAULT;
        }

        if (CanCustomizeTag(client)) {
            response.GetString("name_color", config.name_color, sizeof(config.name_color));
        }
        if (strlen(config.name_color) == 0) {
            response.GetString("default_name_color", config.name_color, sizeof(config.name_color));
            config.chat_type = COLORTYPE_DEFAULT;
        }

        if (CanCustomizeTag(client)) {
            response.GetString("chat_color", config.chat_color, sizeof(config.chat_color));
        }
        if (strlen(config.chat_color) == 0) {
            response.GetString("default_chat_color", config.chat_color, sizeof(config.chat_color));
            config.name_type = COLORTYPE_DEFAULT;
        }

        if (CanCustomizeTag(client)) {
            response.GetString("tag_pattern", config.tag_pattern, sizeof(config.tag_pattern));
        }
        if (strlen(config.tag_pattern) == 0) {
            response.GetString("default_tag_pattern", config.tag_pattern, sizeof(config.tag_pattern));
            config.tag_type = COLORTYPE_DEFAULT;
        }

        if (strlen(config.tag) > 0) {
            if (strlen(config.tag_pattern) > 0) {
                config.tag_type = config.tag_type | COLORTYPE_PATTERN;
            } else if (strlen(config.tag_color) > 0) {
                config.tag_type = config.tag_type | COLORTYPE_SOLID;
            }
        }

        if (strlen(config.name_color) > 0) {
            config.name_type = config.name_type | COLORTYPE_SOLID;
        }

        if (strlen(config.chat_color) > 0) {
            config.chat_type = config.chat_type | COLORTYPE_SOLID;
        }

        player_configs[client] = config;
    }
}

bool CanCustomizeTag(int client) {
    AdminId admin = GetUserAdmin(client);
    if (admin == INVALID_ADMIN_ID || !CheckAccess(admin, "", custom_tag_flags_required, true)) {
        return false;
    }
    return true;
}

public Action GFLDM_OnChatMessage(int author, char[] name, int name_max, char[] msg_body, int body_max) {
    if (player_configs[author].name_type & COLORTYPE_SOLID) {
        Format(name, name_max, "\x07%s%s", player_configs[author].name_color, name);
    } else if (player_configs[author].name_type & COLORTYPE_PATTERN) {
        Colorize(name, name_max, player_configs[author].name_pattern, name);
    } else {
        Format(name, name_max, "{teamcolor[1]}%s", name);
    }

    if (player_configs[author].chat_type & COLORTYPE_SOLID) {
        Format(msg_body, body_max, "\x07%s%s", player_configs[author].chat_color, msg_body);
    } else if (player_configs[author].chat_type & COLORTYPE_PATTERN) {
        Colorize(msg_body, body_max, player_configs[author].chat_pattern, msg_body);
    }

    if (strlen(player_configs[author].tag) > 0) {
        if (player_configs[author].tag_type & COLORTYPE_SOLID) {
            Format(name, name_max, "\x07%s%s %s", player_configs[author].tag_color, player_configs[author].tag, name);
        } else if (player_configs[author].tag_type & COLORTYPE_PATTERN) {
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