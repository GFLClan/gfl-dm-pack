#include <sourcemod>
#include <websocket>
#include <gfldm>
#include <gfldm-web>

public Plugin myinfo = {
    name = "GFLDM Web",
    author = "Dreae",
    description = "GFLDM Web API client",
    version = GFLDM_VERSION, 
    url = "https://github.com/GFLClan/gfl-dm-pack"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("GFLDMWebApi.GFLDMWebApi", native_GFLDMWebApi);
    CreateNative("GFLDMWebApi.SetConnectCallback", native_SetConnectCallback);
    CreateNative("GFLDMWebApi.Call", native_Call);
    RegPluginLibrary("gfldm-web");
}

public any native_GFLDMWebApi(Handle plugin, int num_params) {
    char url[1024];
    GetNativeString(1, url, sizeof(url));

    char api_key[256];
    GetNativeString(2, api_key, sizeof(api_key));

    char channel[256];
    GetNativeString(3, channel, sizeof(channel));

    StringMap api = new StringMap();
    WebSocket ws = WebSocket_FromURL(url);
    ws.SetConnectCallback(Connect_Callback, api);
    ws.SetDisconnectCallback(Disconnect_Callback, api);
    ws.SetReadCallback(WebSocket_JSON, Read_Callback, api);
    ws.Connect();

    api.SetValue("ws", ws);
    api.SetValue("msg_ref", 0);
    api.SetString("api_key", api_key);
    api.SetValue("retry_count", 0);
    api.SetValue("connected", false);
    api.SetString("channel", channel);
    api.SetValue("callbacks", new ArrayList(32));

    return api;
}

public int native_SetConnectCallback(Handle plugin, int num_params) {
    StringMap self = GFLDM_GetNativeHandle(1);
    Function callback = GetNativeFunction(2);
    any data = GetNativeCell(3);

    DataPack pack = new DataPack();
    pack.WriteCell(plugin);
    pack.WriteFunction(callback);
    pack.WriteCell(data);

    self.SetValue("connected_callback", pack);
}

public int native_Call(Handle plugin, int num_params) {
    StringMap self = GFLDM_GetNativeHandle(1);
    char method[256];
    GetNativeString(2, method, sizeof(method));
    JSON payload = GetNativeCell(3);
    Function callback = GetNativeFunction(4);
    any data = GetNativeCell(5);

    JSON msg = CreateMessage(self, method);
    msg.SetJSON("payload", payload);
    int ref = msg.GetInt("ref");

    DataPack pack = new DataPack();
    pack.WriteCell(ref);
    pack.WriteFloat(GetTickedTime());
    pack.WriteCell(plugin);
    pack.WriteFunction(callback);
    pack.WriteCell(data);
    
    ArrayList callbacks;
    self.GetValue("callbacks", callbacks);
    callbacks.Push(pack);

    WebSocket ws;
    self.GetValue("ws", ws);
    ws.Write(msg);
}

public void Connect_Callback(WebSocket ws, any data) {
    StringMap self = data;
    self.SetValue("retry_count", 0);
    self.SetValue("msg_ref", 0);
    Handle timer = CreateTimer(10.0, Timer_Heartbeat, self, TIMER_REPEAT);
    self.SetValue("heartbeat_timer", timer);
    self.SetValue("connected", true);

    char api_key[128];
    self.GetString("api_key", api_key, sizeof(api_key));

    JSON msg = CreateMessage(self, "phx_join");
    JSON payload = new JSON();
    payload.SetString("api_key", api_key);
    msg.SetJSON("payload", payload);
    ws.Write(msg);
    delete msg;
    delete payload;
}

JSON CreateMessage(StringMap self, const char[] event) {
    char channel[256];
    self.GetString("channel", channel, sizeof(channel));

    int msg_ref = IntcrementMsgRef(self);

    JSON msg = new JSON();
    msg.SetString("topic", channel);
    msg.SetString("event", event);
    msg.SetInt("ref", msg_ref);
    msg.SetString("payload", "");

    return msg;
}

int IntcrementMsgRef(StringMap self) {
    int msg_ref;
    self.GetValue("msg_ref", msg_ref);
    self.SetValue("msg_ref", msg_ref + 1);

    return msg_ref;
}

public void Disconnect_Callback(WebSocket ws, any data) {
    LogError("GFLDM API WebSocket disconnected");
    Handle timer;
    StringMap self = data;
    if (self.GetValue("heartbeat_timer", timer)) {
        KillTimer(timer);
        self.Remove("heartbeat_timer");
    }
    self.SetValue("connected", false);

    int retry_count;
    self.GetValue("retry_count", retry_count);
    if (retry_count == 0) {
        self.SetValue("retry_count", 1);
        ws.Connect();
    } else {
        float duration = Pow(2.0, float(retry_count)) - 1.0;
        if (duration > 300.0) {
            duration = 300.0;
        }
        self.SetValue("retry_count", retry_count + 1);
        CreateTimer(duration, Timer_Retry, data);
    }
}

public void Read_Callback(WebSocket ws, JSON response, any data) {
    int ref = response.GetInt("ref");
    StringMap self = data;
    if (ref == 0) {
        DataPack connect_pack;
        if (self.GetValue("connected_callback", connect_pack)) {
            connect_pack.Reset();
            Handle plugin = connect_pack.ReadCell();
            Function callback = connect_pack.ReadFunction();
            any cb_data = connect_pack.ReadCell();

            Call_StartFunction(plugin, callback);
            Call_PushCell(self);
            Call_PushCell(cb_data);
            Call_Finish();
        }
    } else if (ref != -1) {
        ArrayList callbacks;
        if (self.GetValue("callbacks", callbacks)) {
            float time = GetTickedTime();
            for (int c = 0; c < callbacks.Length; c++) {
                DataPack pack = callbacks.Get(c);
                pack.Reset();

                int pack_ref = pack.ReadCell();
                float pack_time = pack.ReadFloat();
                if (ref == pack_ref) {
                    callbacks.Erase(c);
                    Handle plugin = pack.ReadCell();
                    Function callback = pack.ReadFunction();
                    any pack_data = pack.ReadCell();
                    delete pack;
                    JSON payload = response.GetJSON("payload");
                    JSON phx_resp = payload.GetJSON("response");

                    Call_StartFunction(plugin, callback);
                    Call_PushCell(self);
                    Call_PushCell(phx_resp);
                    Call_PushCell(pack_data);
                    Call_Finish();
                    delete payload;
                    delete phx_resp;
                    break;
                } else if (time - pack_time > 30.0) {
                    LogMessage("Removing callback for message ID %d: Timed out after %f seconds", ref, time - pack_time);
                    callbacks.Erase(c);
                    delete pack;
                }
            }
        }
    }
    
    delete response;
}

public Action Timer_Heartbeat(Handle timer, any data) {
    StringMap self = data;
    WebSocket ws;
    self.GetValue("ws", ws);

    JSON msg = new JSON();
    msg.SetString("topic", "phoenix");
    msg.SetString("event", "heartbeat");
    msg.SetString("payload", "");
    msg.SetInt("ref", -1);
    ws.Write(msg);
    delete msg;
    
    return Plugin_Continue;
}

public Action Timer_Retry(Handle timer, any data) {
    StringMap self = data;
    int retry_count;
    self.GetValue("retry_count", retry_count);
    self.SetValue("retry_count", retry_count + 1);
    WebSocket ws;
    self.GetValue("ws", ws);
    ws.Connect();
}

