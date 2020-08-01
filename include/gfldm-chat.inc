#if defined _gfldm_chat_included
    #endinput
#endif
#define _gfldm_chat_included

native void GFLDM_PrintToChatAll(const char[] fmt, any ...);
native void GFLDM_PrintToChatFilter(GFLDM_ChatFilter filter_func, const char[] fmt, any ...);
native void GFLDM_PrintToChat(int client, const char[] fmt, any ...);

typedef GFLDM_ChatFilter = function bool (int client);