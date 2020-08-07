#if defined _gfldm_clientprefs
    #endinput
#endif
#define _gfldm_clientprefs

#include <clientprefs>

#define FIRE_CLIENT_COOKIES(%1) \
    for (int _c = 1; _c <= MaxClients; _c++) {\
        if (AreClientCookiesCached(_c)) {\
            OnClientCookiesCached(_c);\
        }\
    }

#define LOAD_COOKIE_BOOL(%1,%2,%3,%4) \
    public void OnClientCookiesCached(int client) { \
        if (%1.GetClientTime(client) == 0) { \
            %1.Set(client, %3); \
            %2[client] = %4; \
        } else { \
            char buffer[10]; \
            %1.Get(client, buffer, sizeof(buffer)); \
            %2[client] = StrEqual(buffer, "on", false); \
        } \
    }