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

#if defined _gfldm_web_included
    #endinput
#endif
#define _gfldm_web_included

typedef GFLDMWebCall = function void (GFLDMWebApi api, JSON response, any data);
typedef GFLDMWebConnected = function void (GFLDMWebApi api, any data);

methodmap GFLDMWebApi < Handle {
    public native GFLDMWebApi(const char[] url, const char[] api_key, const char[] channel);
    public native void SetConnectCallback(GFLDMWebConnected callback, any data=0);
    public native void Call(const char[] name, JSON args, GFLDMWebCall callback, any data=0);
}