/*
 * RP Gamemode for Black Mesa
 * Compiler: spcomp bm_rp.sp -o bm_rp.smx
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "BM:RP",
    author = "Spirodry",
    description = "RP Gamemode for Black Mesa",
    version = "1.0"
};

// Roles
#define ROLE_SCIENTIST 1
#define ROLE_GUARD     2
#define ROLE_TECH      3
#define ROLE_HECU      4
#define ROLE_MAX       4

int g_Role[MAXPLAYERS+1];
float g_Money[MAXPLAYERS+1];

ConVar gCvarFfScale;
ConVar gCvarForceMenu;
ConVar gCvarStartMoney;
ConVar gCvarSalaryInterval;
ConVar gCvarSalaryScientist;
ConVar gCvarSalaryTech;
ConVar gCvarSalaryGuard;
ConVar gCvarSalaryHecu;
Handle g_SalaryTimer = null;

public void OnPluginStart()
{
    // ConVars
    gCvarFfScale      = CreateConVar("bm_rp_ffscale", "0.0", "Damage scale between players (0=off,1=normal)");
    gCvarForceMenu    = CreateConVar("bm_rp_forcemenu", "1", "Force role menu on spawn (1=yes)");
    gCvarStartMoney   = CreateConVar("bm_rp_startmoney", "100", "Starting money");
    gCvarSalaryInterval   = CreateConVar("bm_rp_salary_interval", "10", "Interval (seconds) between each salary");
    gCvarSalaryScientist  = CreateConVar("bm_rp_salary_scientist", "200", "Scientist salary");
    gCvarSalaryTech       = CreateConVar("bm_rp_salary_tech", "150", "Technician salary");
    gCvarSalaryGuard      = CreateConVar("bm_rp_salary_guard", "0", "Guard salary");
    gCvarSalaryHecu       = CreateConVar("bm_rp_salary_hecu", "220", "HECU salary");

    // Commands
    RegConsoleCmd("sm_role", Command_ShowRoleMenu, "Choose an RP role");
    RegConsoleCmd("sm_money", Command_CheckMoney, "Show your money");
    RegConsoleCmd("sm_pay", Command_Pay, "Pay a player (sm_pay <userid> <amount>)");
    RegConsoleCmd("sm_me", Command_Emote, "Perform an RP action (ex: sm_me searches the table)");

    // Events
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);

    // Initialize arrays
    for (int i = 1; i <= MaxClients; i++)
    {
        g_Role[i] = ROLE_SCIENTIST;
        g_Money[i] = 0.0;
    }

    // Load config file
    AutoExecConfig(true, "bm_rp");

    HookConVarChange(gCvarSalaryInterval, OnSalaryIntervalChanged);

    // Timer for automatic salary
    float interval = GetConVarFloat(gCvarSalaryInterval);
    if (interval < 1.0) interval = 10.0;
    g_SalaryTimer = CreateTimer(interval, Timer_GiveSalary, _, TIMER_REPEAT);

    PrintToServer("[BM:RP] plugin loaded.");
}

public void OnSalaryIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    float interval = GetConVarFloat(gCvarSalaryInterval);
    if (interval < 1.0) interval = 10.0;
    if (g_SalaryTimer != null)
    {
        CloseHandle(g_SalaryTimer);
    }
    g_SalaryTimer = CreateTimer(interval, Timer_GiveSalary, _, TIMER_REPEAT);
}

// ---------------------------
// Menu / role
// ---------------------------
public Action Command_ShowRoleMenu(int client, int args)
{
    if (!IsClientInGame(client) || !IsClientConnected(client)) return Plugin_Handled;

    Menu m = new Menu(MenuHandler_Role);
    m.SetTitle("Choose your role");
    m.AddItem("sc", "Scientist");
    m.AddItem("gd", "Guard");
    m.AddItem("te", "Technician");
    m.AddItem("he", "HECU");
    m.Display(client, 20);
    return Plugin_Handled;
}

public int MenuHandler_Role(Menu m, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char key[4];
        m.GetItem(item, key, sizeof(key));

        if (StrEqual(key, "sc"))
        {
            SetPlayerRole(client, ROLE_SCIENTIST);
        }
        else if (StrEqual(key, "gd"))
        {
            SetPlayerRole(client, ROLE_GUARD);
        }
        else if (StrEqual(key, "te"))
        {
            SetPlayerRole(client, ROLE_TECH);
        }
        else if (StrEqual(key, "he"))
        {
            SetPlayerRole(client, ROLE_HECU);
        }else
        {
            PrintToChat(client, "Invalid choice.");
        }

        char rolename[64];
        RoleToName(g_Role[client], rolename, sizeof(rolename));
        PrintToChatAll("[RP] %N is now %s.", client, rolename);
    }
    else if (action == MenuAction_End)
    {
        delete m;
    }
    return 0;
}

// ---------------------------
// Remove all weapons from a player (by slots)
// ---------------------------
stock void StripPlayerWeapons(int client)
{
    if (!IsClientInGame(client)) return;

    for (int slot = 0; slot <= 6; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (weapon > 0)
        {
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
        }
    }

    for (int slot2 = 0; slot2 <= 12; slot2++)
    {
        int weapon2 = GetPlayerWeaponSlot(client, slot2);
        if (weapon2 > 0)
        {
            RemovePlayerItem(client, weapon2);
            AcceptEntityInput(weapon2, "Kill");
        }
    }
}

// ---------------------------
// SetPlayerRole : strip, give, tp
// ---------------------------
stock void SetPlayerRole(int client, int newRole)
{
    if (!IsClientInGame(client)) return;
    if (newRole < ROLE_SCIENTIST || newRole > ROLE_MAX) newRole = ROLE_SCIENTIST;

    // First remove all previous weapons
    StripPlayerWeapons(client);

    g_Role[client] = newRole;

    // Give basic equipment according to role
    if (newRole == ROLE_SCIENTIST)
    {
        // SCIENTIST: no default weapons
    }
    else if (newRole == ROLE_GUARD)
    {
        GivePlayerItem(client, "weapon_glock");
    }
    else if (newRole == ROLE_TECH)
    {
        GivePlayerItem(client, "weapon_crowbar");
    }
    else if (newRole == ROLE_HECU)
    {
        GivePlayerItem(client, "weapon_crowbar");
        GivePlayerItem(client, "weapon_357");
        GivePlayerItem(client, "weapon_mp5");
        GivePlayerItem(client, "weapon_shotgun");
        GivePlayerItem(client, "weapon_frag");
        GivePlayerItem(client, "weapon_satchel");
        GivePlayerItem(client, "weapon_rpg");
    }

    // Find all info_player_deathmatch and pick a random one
    float origin[3] = {0.0, 0.0, 64.0};
    float angles[3] = {0.0, 0.0, 0.0};
    int spawns[32];
    int count = 0;
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "info_player_deathmatch")) != -1 && count < 32)
    {
        spawns[count++] = ent;
    }
    if (count > 0)
    {
        int pick = GetRandomInt(0, count - 1);
        int spawn = spawns[pick];
        GetEntPropVector(spawn, Prop_Send, "m_vecOrigin", origin);
        GetEntPropVector(spawn, Prop_Send, "m_angRotation", angles);
    }
    float velocity[3] = {0.0, 0.0, 0.0};

    if (IsPlayerAlive(client))
    {
        TeleportEntity(client, origin, angles, velocity);
    }

    char rolename[64];
    RoleToName(g_Role[client], rolename, sizeof(rolename));
    PrintToChatAll("[RP] %N is now %s.", client, rolename);
}

// ---------------------------
// Money / economy
// ---------------------------
public Action Command_CheckMoney(int client, int args)
{
    if (!IsClientInGame(client)) return Plugin_Handled;
    PrintToChat(client, "[RP] You have %.0f credits.", g_Money[client]);
    return Plugin_Handled;
}

public Action Command_Pay(int client, int args)
{
    if (!IsClientInGame(client)) return Plugin_Handled;

    if (args < 2)
    {
        PrintToChat(client, "Usage: sm_pay <userid> <amount>");
        return Plugin_Handled;
    }

    char arg1[16], arg2[16];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    int target = StringToInt(arg1);
    int amount = ArgToInt(arg2, 0);
    if (target <= 0 || !IsClientInGame(target) || target == client)
    {
        PrintToChat(client, "Invalid target.");
        return Plugin_Handled;
    }
    if (amount <= 0)
    {
        PrintToChat(client, "Invalid amount.");
        return Plugin_Handled;
    }
    if (g_Money[client] < float(amount))
    {
        PrintToChat(client, "You don't have enough money.");
        return Plugin_Handled;
    }

    g_Money[client] -= float(amount);
    g_Money[target] += float(amount);
    PrintToChatAll("[RP] %N paid %d credits to %N.", client, amount, target);
    return Plugin_Handled;
}

public Action Timer_GiveSalary(Handle timer, any data)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;

        int role = g_Role[i];
        int salary = 0;
        if (role == ROLE_SCIENTIST)
            salary = GetConVarInt(gCvarSalaryScientist);
        else if (role == ROLE_TECH)
            salary = GetConVarInt(gCvarSalaryTech);
        else if (role == ROLE_GUARD)
            salary = GetConVarInt(gCvarSalaryGuard);
        else if (role == ROLE_HECU)
            salary = GetConVarInt(gCvarSalaryHecu);

        if (salary > 0)
        {
            g_Money[i] += float(salary);
            PrintToChat(i, "[RP] You received your salary of %d credits.", salary);
        }
    }
    return Plugin_Continue;
}

// ---------------------------
// /me emote
// ---------------------------
public Action Command_Emote(int client, int args)
{
    if (!IsClientInGame(client)) return Plugin_Handled;

    if (args < 1)
    {
        PrintToChat(client, "Usage: sm_me <action>");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArgString(buffer, sizeof(buffer));
    TrimString(buffer);
    if (buffer[0] == '\0') return Plugin_Handled;

    PrintToChatAll("*%N %s*", client, buffer);
    return Plugin_Handled;
}

// -----------------------------------
// Events: spawn / serverstart / hurt
// -----------------------------------
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    if (!IsClientInGame(client)) return Plugin_Continue;

    // Initialize starting money
    if (g_Money[client] <= 0.0)
    {
        g_Money[client] = GetConVarFloat(gCvarStartMoney);
    }

    // Force role menu if enabled
    if (GetConVarBool(gCvarForceMenu))
    {
        CreateTimer(1.0, Timer_ShowRole, client);
    }

    return Plugin_Continue;
}

public Action Timer_ShowRole(Handle timer, any data)
{
    int client = data;
    if (!IsClientInGame(client)) return Plugin_Stop;
    ClientCommand(client, "sm_role");
    return Plugin_Stop;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int attackerid = event.GetInt("attacker");
    int victim = GetClientOfUserId(userid);
    int attacker = GetClientOfUserId(attackerid);

    if (victim <= 0 || attacker <= 0) return Plugin_Continue;
    if (!IsClientInGame(victim) || !IsClientInGame(attacker)) return Plugin_Continue;
    if (victim == attacker) return Plugin_Continue;

    int dmg = event.GetInt("dmg_health"); // damage dealt
    float scale = GetConVarFloat(gCvarFfScale);

    if (scale <= 0.0)
    {
        // Cancel damage by restoring health
        int curhp = GetClientHealth(victim);
        SetEntityHealth(victim, curhp + dmg);
        return Plugin_Continue;
    }
    else if (scale < 1.0)
    {
        int expectedKeep = RoundToNearest(dmg * (1.0 - scale));
        if (expectedKeep > 0)
        {
            int curhp = GetClientHealth(victim);
            SetEntityHealth(victim, curhp + expectedKeep);
        }
        return Plugin_Continue;
    }

    return Plugin_Continue;
}

// ---------------------------
// Helpers
// ---------------------------
stock void RoleToName(int r, char[] buffer, int maxlen)
{
    if (r == ROLE_SCIENTIST) { strcopy(buffer, maxlen, "Scientist"); return; }
    if (r == ROLE_GUARD)     { strcopy(buffer, maxlen, "Guard"); return; }
    if (r == ROLE_TECH)      { strcopy(buffer, maxlen, "Technician"); return; }
    if (r == ROLE_HECU)      { strcopy(buffer, maxlen, "HECU"); return; }
    strcopy(buffer, maxlen, "Unknown");
}

stock int StringToRole(const char[] s)
{
    if (StrEqual(s, "scientist", false) || StrEqual(s, "sc", false)) return ROLE_SCIENTIST;
    if (StrEqual(s, "guard", false)     || StrEqual(s, "gd", false)) return ROLE_GUARD;
    if (StrEqual(s, "tech", false)      || StrEqual(s, "te", false)) return ROLE_TECH;
    if (StrEqual(s, "hecu", false)      || StrEqual(s, "he", false)) return ROLE_HECU;
    return ROLE_SCIENTIST;
}

// Helper to safely convert a string to int (returns default value on failure).
stock int ArgToInt(const char[] s, int def)
{
    int val = def;
    if (s[0] == '\0') return def;
    bool ok = true;
    int i = 0;
    if (s[0] == '-') i = 1;
    int slen = strlen(s);
    for (; i < slen; i++)
    {
        if (s[i] < '0' || s[i] > '9') { ok = false; break; }
    }
    if (ok) val = StringToInt(s);
    return val;
}