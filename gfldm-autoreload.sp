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

public Plugin myinfo = {
    name = "GFLDM Autoreload",
    author = "Dreae",
    description = "Configurable automatic weapon reloads",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
};

enum struct ReloadValues {
    int on_kill;
    int on_headshot;
    int max;
}

StringMap weapon_config;

public OnPluginStart() {
    GFLDM_DefineVersion("gfldm_autoreload_version");
    weapon_config = new StringMap();
    HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart() {
    KeyValues kv = new KeyValues("autoreload", "", "");
    char config_path[2048];
    BuildPath(Path_SM, config_path, sizeof(config_path), "configs/gfldm_autoreload.txt");
    if (!kv.ImportFromFile(config_path)) {
        BuildDefaultKV(kv);
        kv.ExportToFile(config_path);
    }

    kv.GotoFirstSubKey();
    char weapon_name[64];
    do {
        kv.GetSectionName(weapon_name, sizeof(weapon_name));

        ReloadValues curr_weapon;
        curr_weapon.on_kill = kv.GetNum("on_kill", 0);
        curr_weapon.on_headshot = kv.GetNum("on_headshot", 0);
        curr_weapon.max = kv.GetNum("max", 0);

        weapon_config.SetArray(weapon_name, curr_weapon, sizeof(curr_weapon)); 
    } while (kv.GotoNextKey());

    delete kv;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!GFLDM_IsValidClient(attacker)) {
        return;
    }

    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));
    Format(weapon, sizeof(weapon), "weapon_%s", weapon);

    ReloadValues curr_weapon;
    if (weapon_config.GetArray(weapon, curr_weapon, sizeof(curr_weapon))) {
        int offset = FindDataMapInfo(attacker, "m_hMyWeapons");
        int weapon_ent = 0;
        for (int c = 0; c < 48; c++) {
            weapon_ent = GetEntDataEnt2(attacker, offset);
            if (IsValidEdict(weapon_ent)) {
                char clsname[64];
                if (GetEdictClassname(weapon_ent, clsname, sizeof(clsname))) {
                    if (StrEqual(clsname, weapon)) {
                        int m_iClip1 = GetEntProp(weapon_ent, Prop_Data, "m_iClip1");
                        if (event.GetBool("headshot")) {
                            m_iClip1 += curr_weapon.on_headshot;
                        } else {
                            m_iClip1 += curr_weapon.on_kill;
                        }

                        if (m_iClip1 > curr_weapon.max) {
                            SetEntProp(weapon_ent, Prop_Data, "m_iClip1", curr_weapon.max);
                        } else {
                            SetEntProp(weapon_ent, Prop_Data, "m_iClip1", m_iClip1);
                        }

                        break;
                    }
                }
            }

            offset += 4;
        }
    }
}

void BuildDefaultKV(KeyValues kv) {
    kv.JumpToKey("weapon_deagle", true);
    kv.SetNum("on_kill", 3);
    kv.SetNum("on_headshot", 7);
    kv.SetNum("max", 7);
    kv.Rewind();

    kv.JumpToKey("weapon_scout", true);
    kv.SetNum("on_kill", 2);
    kv.SetNum("on_headshot", 4);
    kv.SetNum("max", 10);
    kv.Rewind();

    kv.JumpToKey("weapon_ak47", true);
    kv.SetNum("on_kill", 5);
    kv.SetNum("on_headshot", 8);
    kv.SetNum("max", 30);
    kv.Rewind();

    kv.JumpToKey("weapon_m4a1", true);
    kv.SetNum("on_kill", 5);
    kv.SetNum("on_headshot", 8);
    kv.SetNum("max", 30);
    kv.Rewind();

    kv.JumpToKey("weapon_m4a1_silencer", true);
    kv.SetNum("on_kill", 5);
    kv.SetNum("on_headshot", 8);
    kv.SetNum("max", 30);
    kv.Rewind();
}
