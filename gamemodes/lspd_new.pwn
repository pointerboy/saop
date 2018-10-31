/*
    Los Santos Police Department -- CAMP SEVER 
*/

#include <a_samp>
#include "oscar-broman/strlib.inc"
#include "zeex/izcmd.inc"
#include "sscanf2"
#define SECONDS_TO_LOGIN 30
#define AUTOMATED_LOGGING true
#include "mysql/main_db.inc"
#include "player/player_enum.inc"
#include "player/player_dialogs.inc"
#include "player/player_database.inc"
#include "player/player_functions.inc"

main()
{
    if(AUTOMATED_LOGGING)
    {
        print("SAMP SERVER: Logging has been turned on by the default.");
    }
}

public OnGameModeInit()
{
	new MySQLOpt: option_id = mysql_init_options();

	mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id); // AUTO_RECONNECT is enabled for this connection handle only
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("SERVER: MySQL connection has failed. Locking the server.");
		SendRconCommand("hostname LSPD Camp: AUTOMATED RESCUE");
        SendRconCommand("password *letmein*");
		return 1;
	}

	print("MySQL connection is successful.");
	SetupPlayerTable();
	return 1;
}

public OnGameModeExit()
{
	for (new i = 0, j = GetPlayerPoolSize(); i <= j; i++) // GetPlayerPoolSize function was added in 0.3.7 version and gets the highest playerid currently in use on the server
	{
		if (IsPlayerConnected(i))
		{
			OnPlayerDisconnect(i, 1);
		}
	}

	mysql_close(g_SQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
	g_MysqlRaceCheck[playerid]++;

	static const empty_player[E_PLAYERS];
	Player[playerid] = empty_player;

	GetPlayerName(playerid, Player[playerid][Name], MAX_PLAYER_NAME);

	new query[103];
	mysql_format(g_SQL, query, sizeof query, "SELECT * FROM `players` WHERE `username` = '%e' LIMIT 1", Player[playerid][Name]);
	mysql_tquery(g_SQL, query, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	g_MysqlRaceCheck[playerid]++;

	UpdatePlayerData(playerid, reason);

	if (cache_is_valid(Player[playerid][Cache_ID]))
	{
		cache_delete(Player[playerid][Cache_ID]);
		Player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;
	}

	if (Player[playerid][LoginTimer])
	{
		KillTimer(Player[playerid][LoginTimer]);
		Player[playerid][LoginTimer] = 0;
	}

	Player[playerid][IsLoggedIn] = false;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerInterior(playerid, Player[playerid][Interior]);
	SetPlayerPos(playerid, Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos]);
	SetPlayerFacingAngle(playerid, Player[playerid][A_Pos]);
	
	SetCameraBehindPlayer(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	UpdatePlayerDeaths(playerid);
	UpdatePlayerKills(killerid);
	return 1;
}
