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