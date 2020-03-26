/* * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Super - Other Commands
 * Developed/Maintained by SuperCentral.co Scripting Team
 * Last Update: Jan 17 2014
 * 
 * Minimum Requirements
 * AMX Mod X 1.8.0
 * AMX Super 5.0
 * 
 * Credits
 * If I forgot you, let me know what you did and I will add you
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Mod X script.
 *
 *   AMX Super - Other Commands (amx_super-others.sma)
 *   Copyright (C) 2013-2014 SuperCentral.co
 *
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License
 *   as published by the Free Software Foundation; either version 2
 *   of the License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 *   In addition, as a special exception, the author gives permission to
 *   link the code of this program with the Half-Life Game Engine ("HL
 *   Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *   L.L.C ("Valve"). You must obey the GNU General Public License in all
 *   respects for all of the code used other than the HL Engine and MODs
 *   from Valve. If you modify this file, you may extend this exception
 *   to your version of the file, but you are not obligated to do so. If
 *   you do not wish to do so, delete this exception statement from your
 *   version.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
 /*
* -) DEAD CHAT 
* -) LOADING SOUNDS 
* -) SPECTATOR BUG FIX 
* -) "SHOWNDEAD" SCOREBOARD FIX 
* -) AFK BOMB TRANSFER 
* -) C4 TIMER 
* -) STATS MARQUEE REMOVE
* -) SPAWN PROTECTION 
* -) AFK Manager
*/
/*********************
*					 *
* Customizable stuff *
*					 * 
*********************/

/*** Loading sounds ***/
// #define CUSTOM_LOADING_SONGS		// Uncomment this if you use custom loading songs
new g_szSoundList[][] = 
{
	"media/Half-Life01",
	"media/Half-Life02",
	"media/Half-Life03",
	"media/Half-Life04",
	"media/Half-Life06",
	"media/Half-Life08",
	"media/Half-Life10",
	"media/Half-Life11",
	"media/Half-Life12",
	"media/Half-Life13",
	"media/Half-Life14",
	"media/Half-Life15",
	"media/Half-Life16",
	"media/Half-Life17"
};


/*** Damage HUD ***/
// #define DAMAGE_RECEIVED			// If uncommented, Damage HUD also shows received damage

/*** AFK Manager **/
#define AFK_ADMIN_IMMUNE 		ADMIN_IMMUNITY // Which flag for admins not to be kicked for being AFK
#define AFK_CHECK_INTERVAL 		5		// How often to check for AFK players

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)
#define fm_fake_touch(%1,%2) dllfunc(DLLFunc_Touch, %1, %2)

/*** C4 timer ***/
new const g_szC4TimerMsg[] = "Detonation time initialized.";	// HUD message printed when bomb is planted.

/*********************
*					 *
* End customisations *
*					 * 
*********************/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <csx>

#pragma semicolon 1

new const g_szC4TimerSprites[][] = { "bombticking", "bombticking1" };

// Cvar pointers
new g_pEnterMsg;
new g_pLeaveMsg;
new g_pEnterMsgEnable;
new g_pLeaveMsgEnable;
new g_pHostname;
new g_pDamage;
new g_pLoadingSounds;
new g_pC4TimerTeams;
new g_pC4TimerFlash;
new g_pC4TimerMsg;
new g_pC4TimerSprite;
new g_pC4Timer;
new g_pStatsMarquee;
new g_pStaMarPlayerAmount;
new g_pStaMarHudPos;
new g_pStaMarFullTime;
new g_pStaMarTimeInBetween;
new g_pSpawnProtect;
new g_pSpawnProtectTime;
new g_pSpawnProtectGlow;
new g_pSpawnProtectMsg;
new g_pFreezeTime;
new g_pAFKTransferTime;
new g_pAFKTransferTime_Dispatch;
new g_pAFKImmuneTime;
new g_pAFKMaxTime;
new g_pAFKCheckAllow;
new g_pReservation;

// damage done
new g_iSyncHud;

#if defined DAMAGE_RECEIVED
	new g_iSyncHud2;
#endif

// C4 Timer
new g_iMsgShowTimer;
new g_iMsgRoundTime;
new g_iMsgScenario;

// AFK Manager
new bool:g_bFreezetime;
new bool:g_bSpawn;
new bool:g_bBombPlanting;
new g_iBombCarrier;
new g_iOrigin[33][3];
new g_iTime[33];
new g_iAFKTime[33];
new g_iSpecGameTime[33];

new const g_szSpecKickChat[] = "AMX_SUPER_AFK_SPEC_KICK_CHAT";
new const g_szAFKKickChat[]  = "AMX_SUPER_AFK_KICK_CHAT";
new const g_szAFKSpecChat[] = "AMX_SUPER_AFK_TO_SPEC_CHAT";

new const g_szTeamName[2][] = {"TERRORIST", "CT"};

// Stats marquee
new g_iCurrentRankPos;


// enter / leave messages
new g_szName[33][35];


// "Showndead" scoreboard fix
new g_iMsgTeamInfo;


// Misc
new g_iMaxPlayers;

public plugin_init()
{
	register_plugin("Amx Super Others", "5.0.2", "SuperCentral.co");
	
	g_pLeaveMsgEnable					= register_cvar("amx_leavemessage_enable", "1");
	g_pEnterMsgEnable 					= register_cvar("amx_joinmessage_enable", "1");
	g_pEnterMsg 						= register_cvar("amx_join_message", "%name% has joined!\nEnjoy the Server!\nCurrent Ranking is %rankpos%");
	g_pLeaveMsg 						= register_cvar("amx_leave_message", "%name% has left!\nHope to see you back sometime."); 
	g_pDamage							= register_cvar("bullet_damage", "1");
	g_pLoadingSounds					= register_cvar("amx_loadsong", "1");
	g_pC4TimerTeams						= register_cvar("amx_showc4timer", "3");
	g_pC4TimerFlash						= register_cvar("amx_showc4flash", "1");
	g_pC4TimerMsg						= register_cvar("amx_showc4msg", "1");
	g_pC4TimerSprite					= register_cvar("amx_showc4sprite", "1");
	g_pStatsMarquee 					= register_cvar("stats_marquee", "1");
	g_pStaMarPlayerAmount 				= register_cvar("amx_marqplayeramount","40");
	g_pStaMarHudPos						= register_cvar("amx_marqvertlocation","2");
	g_pStaMarFullTime 					= register_cvar("amx_marqfulltime", "600");
	g_pStaMarTimeInBetween 				= register_cvar("amx_marqtimebetween","6.0");
	g_pSpawnProtect 					= register_cvar("amx_spawnprotect", "1");
	g_pSpawnProtectTime 				= register_cvar("amx_spawnprotect_time", "3");
	g_pSpawnProtectGlow 				= register_cvar("amx_spawnprotect_glow", "1");
	g_pSpawnProtectMsg					= register_cvar("amx_spawnprotect_message", "1");
	g_pAFKTransferTime_Dispatch			= register_cvar("afk_bombtransfer_fm_DispatchSpawn","7");
	g_pAFKTransferTime 					= register_cvar("afk_bombtransfer_time", "15");
	g_pAFKImmuneTime					= register_cvar("amx_immune_time","5");
	g_pAFKMaxTime						= register_cvar("amx_max_afktime","45");
	g_pAFKCheckAllow					= register_cvar("amx_afkcheck_allow","1");
	g_pReservation						= register_cvar("amx_reservation", "0");
	
	g_pC4Timer				= get_cvar_pointer("mp_c4timer");
	g_pHostname				= get_cvar_pointer("hostname");
	g_pFreezeTime			= get_cvar_pointer("mp_freezetime");
	
	// Damage done
	register_event("Damage", "EventDamage", "b", "2!0", "3=0", "4!0");
	g_iSyncHud = CreateHudSyncObj();
#if defined DAMAGE_RECEIVED
	g_iSyncHud2 = CreateHudSyncObj();
#endif

	
	// C4 Timer
	register_logevent("LogeventBombPlanted", 3, "2=Planted_The_Bomb");
	g_iMsgShowTimer	= get_user_msgid("ShowTimer");
	g_iMsgRoundTime	= get_user_msgid("RoundTime");
	g_iMsgScenario	= get_user_msgid("Scenario");

	
	// Stats Marquee
	set_task(15.0, "TaskShowStatsMarquee");

	
	// Spawn Protection
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1);
	
	
	// Scoreboard fix
	g_iMsgTeamInfo = get_user_msgid("TeamInfo");
	
	// AFK Manager
	register_event("TeamInfo", "EventSpectate", "a", "2=UNASSIGNED", "2=SPECTATOR");
	register_event("TeamInfo", "EventChooseTeam", "a", "2=TERRORIST", "2=CT");
	set_task(float(AFK_CHECK_INTERVAL), "TaskAfkCheck", _, _, _, "b");
	
	// AFK Bomb Transfer Events
	register_event("WeapPickup", "EventBombPickup", "be", "1=6");
	register_event("BarTime", "EventBarTime", "be");
	register_event("TextMsg", "EventBombDrop", "bc", "2=#Game_bomb_drop");
	register_event("TextMsg", "EventBombDrop", "a", "2=#Bomb_Planted");
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	
	// AFK Bomb Transfer Logevents
	register_logevent("LogeventRoundStart", 2, "1=Round_Start");
	
	// AFK Bomb Transfer Task
	set_task(1.0, "TaskAfkBombCheck", _, _, _, "b"); // AFK Bomb Transfer core loop
	
	// Misc
	g_iMaxPlayers = get_maxplayers();
	
}


public plugin_cfg()
{
	new szInfo[2];
	get_localinfo("amx_super_executed", szInfo, charsmax(szInfo));
	
	if(szInfo[0] != '1')
	{
		set_localinfo("amx_super_executed", "1");
		
		server_cmd("exec addons/amxmodx/configs/amx_super.cfg");
		server_exec();

		set_task(5.0, "TaskRemoveExecInfo");
	}
}


public TaskRemoveExecInfo()
	set_localinfo("amx_super_executed", "0");


/* AFK Manager */
public EventSpectate()
{
	new id = read_data(1);
	if(is_user_connected(id) && !g_iSpecGameTime[id])
		g_iSpecGameTime[id] = floatround(get_gametime());
}

public EventChooseTeam()
{
	new id = read_data(1);
	
	if(is_user_connected(id))
		ClearVars(id);
}

ClearVars(id) 
{
	g_iOrigin[id][0] = 0;
	g_iOrigin[id][1] = 0;
	g_iOrigin[id][2] = 0;
	g_iAFKTime[id] = 0;
	g_iSpecGameTime[id] = 0;
}

public TaskAfkCheck()
{
	if(!get_pcvar_num(g_pAFKCheckAllow))
		return;
	
	static iPlayers[32], iNum, iPlayer, bool:bAllAFK, iOrigin[3];
	for(new i = 0; i < 2; i++)
	{
		get_players(iPlayers, iNum, "ae", g_szTeamName[i]);
		bAllAFK = true;
		for(new j = 0; j < iNum; j++)
		{
			iPlayer = iPlayers[j];
			get_user_origin(iPlayer, iOrigin);
			if(IsUserAFK(iPlayer, iOrigin))
			{
				g_iAFKTime[iPlayer] += AFK_CHECK_INTERVAL;
				if(g_iAFKTime[iPlayer] < get_pcvar_num(g_pAFKMaxTime))
					bAllAFK = false;
			}
			else
			{
				g_iAFKTime[iPlayer] = 0;
				g_iOrigin[iPlayer] = iOrigin;
				bAllAFK = false;
			}
		}
		
		if(!bAllAFK)
			continue;
		
		for(new j = 0; j < iNum; j++)
		{
			iPlayer = iPlayers[j];
			ChatMessage(iPlayer, g_szAFKSpecChat);
			UserToSpec(iPlayer);
		}
	}
}

public EventBombPickup(id)
{
	g_iBombCarrier = id;
}

public EventBarTime(id)
{
	if(id == g_iBombCarrier)
	{
		g_bBombPlanting = bool:read_data(1);
		get_user_origin(id, g_iOrigin[id]);
		g_iTime[id] = 0;
	}
}

public EventBombDrop()
{
	g_bSpawn = false;
	g_bBombPlanting = false;
	g_iBombCarrier = 0;
}

public EventNewRound()
{
	g_bFreezetime = true;
	g_bSpawn = true;
	g_bBombPlanting = false;
	g_iBombCarrier = 0;
}

public LogeventRoundStart()
{
	g_bFreezetime = false;
	g_bSpawn = false;
	g_bBombPlanting = false;
}

public TaskAfkBombCheck()
{
	if(g_bFreezetime)
		return;
	
	new iPlayers[32], iNum, iPlayer, iOrigin[3];
	get_players(iPlayers, iNum, "ae", "TERRORIST");

	for(new i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		get_user_origin(iPlayer, iOrigin);
		if(iOrigin[0] != g_iOrigin[iPlayer][0] || iOrigin[1] != g_iOrigin[iPlayer][1] || (iPlayer == g_iBombCarrier && g_bBombPlanting))
		{
			g_iTime[iPlayer] = 0;
			g_iOrigin[iPlayer][0] = iOrigin[0];
			g_iOrigin[iPlayer][1] = iOrigin[1];
			
			if(g_bSpawn && iPlayer == g_iBombCarrier)
				g_bSpawn = false;
		}
		
		else
			g_iTime[iPlayer]++;
	}

	if(!g_iBombCarrier || iNum < 2)
		return;
			
	new iMaxTime = get_pcvar_num(g_bSpawn ? g_pAFKTransferTime_Dispatch : g_pAFKTransferTime);
	
	if(iMaxTime <= 0 || g_iTime[g_iBombCarrier] < iMaxTime)
		return;
	
	get_user_origin(g_iBombCarrier, iOrigin);
	new iMinDist = 999999, iDist, iRecipient, iOrigin2[3];
	
	for(new i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		if(g_iTime[iPlayer] < iMaxTime)
		{
			get_user_origin(iPlayer, iOrigin2);
			iDist = get_distance(iOrigin, iOrigin2);
			if(iDist < iMinDist) 
			{
				iMinDist = iDist;
				iRecipient = iPlayer;
			}
		}
	}
	
	if(!iRecipient)
		return;
	
	new iCarrier = g_iBombCarrier;
	engclient_cmd(iCarrier, "drop", "weapon_c4");
	
	new iBomb;
	
	if((iBomb = fm_find_ent_by_class(-1, "weapon_c4")) == -1)
		return;
	
	new iBackpack = pev(iBomb, pev_owner);
	if(iBackpack <= g_iMaxPlayers)
		return;
	
	set_pev(iBackpack, pev_flags, pev(iBackpack, pev_flags) | FL_ONGROUND);
	fm_fake_touch(iBackpack, iRecipient);
	
	set_hudmessage(0, 255, 0, 0.35, 0.8, _, _, 7.0);
	new szMessage[128], szCarrierName[32], szReceiverName[32];
	get_user_name(iCarrier, szCarrierName, 31);
	get_user_name(iRecipient, szReceiverName, 31);
	
	format(szMessage, 127, "%L", LANG_PLAYER, "AMX_SUPER_BOMB_TRANSFER", szReceiverName, szCarrierName);
	for (new i = 0; i < iNum; i++)
		show_hudmessage(iPlayers[i], "%s", szMessage);
	
	set_hudmessage(255, 255, 0, 0.42, 0.3, _, _, 7.0, _, _, 3);
	show_hudmessage(iRecipient, "You got the bomb!");
}


bool:IsUserAFK(id, const iOrigin[3]) 
{
	return (iOrigin[0] == g_iOrigin[id][0] && iOrigin[1] == g_iOrigin[id][1]);
}

ChatMessage(id, const szText[]) 
{
	new szName[32];
	get_user_name(id, szName, 31);
	client_print(0, print_chat, "%L", LANG_PLAYER, szText, szName);
}

ClientKick(id, const szReason[] = "") 
{
	server_cmd("kick #%d ^"%L^"", get_user_userid(id), szReason);
	server_exec();
}

stock UserToSpec(id) 
{
	user_kill(id, 1);
	engclient_cmd(id, "jointeam", "6");
}

/* Loading Sounds
 *---------------
*/
#if defined CUSTOM_LOADING_SONGS
public plugin_precache()
{
	for(new i = 0; i < sizeof(g_szSoundList); i++)
		precache_generic(g_szSoundList[i]);
}
#endif


public client_connect(id)
{
	/*	Loading sounds
	 *----------------
	*/
	if(get_pcvar_num(g_pLoadingSounds))
		client_cmd(id, "mp3 play ^"%s^"", g_szSoundList[random(sizeof(g_szSoundList))]);

	/* Showndead scoreboard fix
	 *-------------------------
	*/	
	if(!is_user_bot(id)) 
	{ 
		message_begin(MSG_ALL, g_iMsgTeamInfo, _, id);
		write_byte(id);
		write_string("UNASSIGNED");
		message_end(); 
	}
	
	/* AFK Manager */
	new iReservation = get_pcvar_num(g_pReservation);
	
	if(!get_pcvar_num(g_pAFKCheckAllow) || !iReservation)
		return PLUGIN_CONTINUE;
	
	if(get_playersnum(1) <= g_iMaxPlayers - iReservation || is_user_bot(id))
		return PLUGIN_CONTINUE;
	
	new iPlayers[32], iNum, iPlayer, szTeam[2];
	new iCandidate, iCTime;
	get_players(iPlayers, iNum, "b");
	for(new i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		if(get_user_flags(iPlayer) & AFK_ADMIN_IMMUNE)
			continue;
			
		get_user_team(iPlayer, szTeam, 1);
		if(((szTeam[0] == 'U' && get_user_time(iPlayer, 1) > get_pcvar_num(g_pAFKImmuneTime)) || szTeam[0] == 'S') && (!iCTime || g_iSpecGameTime[iPlayer] < iCTime))
		{
			iCTime = g_iSpecGameTime[iPlayer];
			iCandidate = i;
		}
	}
	
	if(iCandidate)
	{
		ChatMessage(iCandidate, g_szSpecKickChat);
		ClientKick(iCandidate);
		return PLUGIN_CONTINUE;
	}
	
	new iOrigin[3], iAFKTime;
	get_players(iPlayers, iNum, "a");
	for(new i = 0; i < iNum; i++)
	{
		iPlayer = iPlayers[i];
		get_user_origin(iPlayer, iOrigin);
		if(!IsUserAFK(iPlayer, iOrigin))
		{
			g_iAFKTime[i] = 0;
			g_iOrigin[id] = iOrigin;
			continue;
		}
		
		iAFKTime = g_iAFKTime[i];
		if(iAFKTime >= get_pcvar_num(g_pAFKMaxTime) && iAFKTime > iCTime)
		{
			iCTime = iAFKTime;
			iCandidate = i;
		}
	}
		
	if(iCandidate)
	{
		ChatMessage(iCandidate, g_szAFKKickChat);
		ClientKick(iCandidate);
	}
	
	return PLUGIN_CONTINUE;
}


/* Enter / Leave messages
 *-----------------------
*/
public client_putinserver(id)
{
	if(get_pcvar_num(g_pEnterMsgEnable) && !is_user_bot(id))
		set_task(2.0, "TaskShowEnterMsg", id);
}

public client_disconnect(id)
{
	if(get_pcvar_num(g_pLeaveMsgEnable) && !is_user_bot(id))
		set_task(2.0, "TaskShowLeaveMsg", id);
}

public TaskShowEnterMsg(id)
{	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	new szMessage[192], szHostname[64];
	get_pcvar_string(g_pEnterMsg, szMessage, charsmax(szMessage));
	get_pcvar_string(g_pHostname, szHostname, charsmax(szHostname));
	get_user_name(id, g_szName[id], charsmax(g_szName[]));
	
	if(contain(szMessage, "%rankpos%") != -1)
	{
		new Stats[8];
		new iRank = get_user_stats(id, Stats, Stats);
		
		num_to_str(iRank, Stats, charsmax(Stats));
		replace(szMessage, charsmax(szMessage), "%rankpos%", Stats);
	}

	replace(szMessage, charsmax(szMessage), "%name%", g_szName[id]);
	
	replace_all(szMessage, charsmax(szMessage), "\n", "^n");
	
	if(get_user_flags(id) & ADMIN_RESERVATION)
	{
		set_hudmessage(255, 0, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15);
		show_hudmessage(0, szMessage);
	}
	
	else
	{
		set_hudmessage(0, 255, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15); 
		show_hudmessage(0, szMessage);
	}
	
	return PLUGIN_HANDLED;
}

public TaskShowLeaveMsg(id)
{
	new szMessage[192];
	get_pcvar_string(g_pLeaveMsg, szMessage, charsmax(szMessage));

	if(contain(szMessage, "%hostname%") != -1)
	{
		new szHostname[64];
		get_pcvar_string(g_pHostname, szHostname, charsmax(szHostname));
		replace(szMessage, charsmax(szMessage), "%hostname%", szHostname);
	}
	
	replace(szMessage, 191, "%name%", g_szName[id]);
	replace_all(szMessage, 191, "\n", "^n");

	set_hudmessage(255, 0, 255, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15);
	show_hudmessage(0, szMessage);
	
	return PLUGIN_HANDLED;
}


/* Damage done
 *------------
*/
public EventDamage(id)
{
	if(!get_pcvar_num(g_pDamage))
		return;
	
	static iAttacker; iAttacker = get_user_attacker(id);
	static iDamage; iDamage = read_data(2);
		
#if defined DAMAGE_RECEIVED
	set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1);
	ShowSyncHudMsg(id, g_iSyncHud2, "%i^n", iDamage);
#endif

	if(1 <= iAttacker <= g_iMaxPlayers)
	{
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1);
		ShowSyncHudMsg(iAttacker, g_iSyncHud, "%i^n", iDamage);		
	}
}


/*	Spectator bug fix
 *-------------------
*/
public FwdPlayerKilledPost(id)
	set_task(1.0, "TaskSpecBugFix", id);
	
public TaskSpecBugFix(id)
	client_cmd(id, "+duck; -duck; spec_menu 0");

	
/* C4 timer
 *---------
*/
public LogeventBombPlanted()
{
	new iC4TimerTeams = get_pcvar_num(g_pC4TimerTeams);
	
	if(iC4TimerTeams)
	{
		new iPlayers[32], iNum;
		
		switch(iC4TimerTeams)
		{
			case 1: get_players(iPlayers, iNum, "ace", "TERRORIST");
			case 2: get_players(iPlayers, iNum, "ace", "CT");
			case 3: get_players(iPlayers, iNum, "ac");
			default: return;
		}
		
		new id;
		for(new i = 0; i < iNum; i++)
		{
			id = iPlayers[i];
			
			message_begin(MSG_ONE_UNRELIABLE, g_iMsgShowTimer, _, id);
			message_end();
			
			message_begin(MSG_ONE_UNRELIABLE, g_iMsgRoundTime, _, id);
			write_short(get_pcvar_num(g_pC4Timer));
			message_end();
			
			message_begin(MSG_ONE_UNRELIABLE, g_iMsgScenario, _, id);
			write_byte(1);
			write_string(g_szC4TimerSprites[clamp(get_pcvar_num(g_pC4TimerSprite), 0, sizeof(g_szC4TimerSprites) - 1)]);
			write_byte(150);
			write_short(get_pcvar_num(g_pC4TimerFlash) ? 20 : 0);
			message_end();
		}
		
		if(get_pcvar_num(g_pC4TimerMsg))
		{
			set_hudmessage(255, 180, 0, 0.44, 0.87, 2, 6.0, 6.0);
			show_hudmessage(id, g_szC4TimerMsg);
		}
	}
}

/* Stats Marquee
 *--------------
*/
public TaskShowStatsMarquee()
{
	if(get_pcvar_num(g_pStatsMarquee))
	{
		new iStats[8], iBody[8], szName[31];
		new iPlayerAmount = get_pcvar_num(g_pStaMarPlayerAmount);
		new Float: flTimeBetween = get_pcvar_float(g_pStaMarTimeInBetween);
		
		get_stats(g_iCurrentRankPos++, iStats, iBody, szName, 31);	

		if(g_iCurrentRankPos > iPlayerAmount || !strlen(szName))
		{
			g_iCurrentRankPos = 0;
			set_task(get_pcvar_float(g_pStaMarFullTime), "TaskShowStatsMarquee");
		}
		
		else
		{
			set_task(flTimeBetween, "TaskShowStatsMarquee");
			
			set_hudmessage(0, 240, 10, 0.70, get_pcvar_num(g_pStaMarHudPos) == 1 ? -0.74 : 0.77, 0, flTimeBetween, flTimeBetween, 0.5, 0.15, -1);
			show_hudmessage(0,"Server Top %d^n%s^nRank %d %d kills %d deaths", iPlayerAmount, szName, g_iCurrentRankPos, iStats[0], iStats[1]);
		}
	}
	
	else
		set_task(60.0, "TaskShowStatsMarquee");
}

/* Spawn Protection
 *-----------------
*/
public FwdPlayerSpawnPost(id)
{													  		  // In case he has permgod, don't remove it.
	if(is_user_alive(id) && get_pcvar_num(g_pSpawnProtect) && !get_user_godmode(id))
	{
		new Float: flProtectTime = get_pcvar_float(g_pSpawnProtectTime) + get_pcvar_float(g_pFreezeTime);
		
		if(get_pcvar_num(g_pSpawnProtectGlow))
			set_user_rendering(id, kRenderFxGlowShell, 100, 150, 0, kRenderTransAlpha, 100);
			
		if(get_pcvar_num(g_pSpawnProtectMsg))
		{
			set_hudmessage(255, 1, 1, -1.0, -1.0, 0, 6.0, flProtectTime, 0.1, 0.2, 4);
			show_hudmessage(id, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_MESSAGE", get_pcvar_num(g_pSpawnProtectTime));
		}
		
		set_user_godmode(id, 1);
		
		set_task(flProtectTime, "TaskRemoveSpawnProtection", id);
	}
}

public TaskRemoveSpawnProtection(id)
{
	if(is_user_alive(id))
	{
		if(get_pcvar_num(g_pSpawnProtectTime))
			set_user_rendering(id);
			
		set_user_godmode(id, 0);
	}
}


