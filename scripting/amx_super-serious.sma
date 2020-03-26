/* * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Super - Serious Commands
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
 *   AMX Super - Serious Commands (amx_super-serious.sma)
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

// Serious commands
/*
 *	Nr 		COMMAND			CALLBACK FUNCTION	ADMIN LEVEL
 *			
 *	1)		amx_alltalk		Cmd_AllTalk			ADMIN_LEVEL_A
 *	2)		amx_extend		Cmd_Extend			ADMIN_LEVEL_A
 *	3)		amx_(un)gag		Cmd_(Un)Gag			ADMIN_LEVEL_A
 *	4)		amx_pass		Cmd_Pass			ADMIN_PASSWORD
 *	5)		amx_nopass		Cmd_NoPass			ADMIN_PASSWORD
 *	6)		admin voicecomm	Cmd_PlusAdminVoice	ADMIN_VOICE
 *							Cmd_MinAdminVoice	ADMIN_VOICE
 *	7)		amx_transfer	Cmd_Transfer		ADMIN_LEVEL_D
 * 	8)		amx_swap		Cmd_Swap			ADMIN_LEVEL_D
 *	9)		amx_teamswap	Cmd_TeamSwap		ADMIN_LEVEL_D
 *	10)		amx_lock		Cmd_Lock			ADMIN_LEVEL_D
 *	11)		amx_unlock		Cmd_Unlock			ADMIN_LEVEL_D
 *	12)		amx_badaim		Cmd_BadAim			ADMIN_LEVEL_D
 *	13)		amx_exec		Cmd_Exec			ADMIN_BAN
 *	14a)	amx_restart		Cmd_Restart			ADMIN_BAN
 *	14b)	amx_shutdown	Cmd_Restart			ADMIN_RCON
 *	15)		say /gravity	Cmd_Gravity				/
 *	16)		say /alltalk	Cmd_Alltalk				/
 *	17)		say /spec		Cmd_Spec					/
 *	18)		say /unspec		Cmd_UnSpec				/
 *	19)		say /admin(s)	Cmd_Admins				/
 *	20)		say /fixsound	Cmd_FixSound				/
 *	21)			/				/					/			(Dead chat)
*/
/*********************
*					 *
* Customizable stuff *
*					 * 
*********************/

/*** Admin levels ***/
#define ADMIN_VOICE			ADMIN_RESERVATION		// admin voicecomm
#define ADMIN_CHECK 		ADMIN_KICK 				// say /admin(s)


/*** Taskids ***/
// Change these numbers if other plugins interfere with them.
#define TASK_GAG 			5446			// Taskid for gag. Change this number if it interferes with any other plugins.
#define TASKID_UNBADAIM		15542		// taskid. Change this number if it interfers with any other plugins


/*** amx_extend ***/
// #define MAPCYCLE						// Uncomment this to use the mapcycle.txt file.
#define EXTENDMAX 			9			// Maximum number of times a map may be extended by anyone.
#define EXTENDTIME 			15			// Maximum amount of time any map can be extended at once.
#define MAX_MAPS 			32			// Change this if you have more than 32 maps in mapcycle.


// say /admins chat color - green
new const COLOR[] = "^x04";

/*********************
*					 *
* End customisations *
*					 * 
*********************/


#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31))) 


// amx extend
new g_iExtendLimit;

#if defined MAPCYCLE
	new g_iMapsNum;
	new bool: g_bCyclerFile;
#endif


//		amx_gag
#define SPEAK_NORMAL		0
#define SPEAK_MUTED			1		
#define SPEAK_ALL			2		
#define SPEAK_LISTENALL		4			

enum eGagFlags
{
	NONE,
	CHAT,
	TEAM_CHAT,
	VOICE,
};

new eGagFlags: g_GagFlags[33];
new g_iSpeak[33];
new g_szGagReason[33][50];


// amx_badaim
#define TERRO 	0
#define COUNTER 1
#define AUTO	4
#define SPEC	5



// admin voicecomm
enum SPKSETTINGS
{
	SPEAK_MUTED2, 	// 0
	SPEAK_NORMAL2, 	// 1
	SPEAK_ALL2,		// 2
	JUNK,			// 3	
	JUNK,			// 4
	SPEAK_ADMIN		// 5
};

new SPKSETTINGS: g_PlayerSpk[33]
new g_iAdminBit
new g_iVoiceMask[33]

// Team locker
new const Teamnames[6][] = 
{
	"Terrorists",
	"Counter-Terrorists",
	"",
	"",
	"Auto",
	"Spectator"
};

new bool: g_bBlockJoin[6];


// amx_badaim
new bool: g_bHasBadAim[33];


// amx_exec
new bool: g_bAllowsAllCommands[33];
new g_szAlwaysBlockedCmds[][] = 
{
	"alias",
	"connect",
	"retry",
	"bind",
	"unbind",
	"unbindall",
	"quit",
	"restart",
	"exit",
	"exec",
	"writecfg",
	"ex_interp",
	"removedemo",
	"cl_",
	"gl_",
	"m_",
	"r_",
	"hud_",
	"kill"
};

new g_szFilterStuffCmdBlockedCmds[][] = 
{
	"setinfo",
	"say",
	"developer",
	"timerefresh",
	"rate",
	"fps_max",
	"speak_enabled",
	"voice_enable",
	"sensitivity",
	"sys_ticrate",
	"volume",
	"mp3volume"
};


// amx shutdown
enum eShutDownModes
{
	RESTART,
	SHUTDOWN,
};

new const g_szShutdownNames[eShutDownModes][] = 
{
	"restart",
	"shut down"
};

new eShutDownModes: g_ShutDownMode,
	bool: g_bIsShuttingDown = false
;

// say /admin(s)
new g_iMsgSayText;


// say /(un)spec
new CsTeams: g_OldTeam[33];


// For show_activity / log_amx team messages.
enum eCmdTeam
{
	ALL,
	T,
	CT
};

new const g_TeamNames[eCmdTeam][] = 
{ 
	"all",
	"terrorist", 
	"counter-terrorist" 
};


// Cvar pointers
new g_pAllTalk
new g_pTimeLimit
new g_pDefaultGagTime
new g_pGagSound
new g_pGagBlockNameChange
new g_pPassword
new g_pGravity
new g_pAllowSoundFix
new g_pAllowSpec
new g_pAllowPublicSpec
new g_pAdminCheck
new g_pContact	
new g_pBadAimBan
new g_pDeadChat


// misc
new g_iMaxPlayers;

public plugin_init()
{
	register_plugin("Amx Super Serious", "5.0.2", "SuperCentral.co");
	register_dictionary("amx_super.txt");
	
	g_pAllTalk 				= get_cvar_pointer("sv_alltalk");
	g_pTimeLimit 			= get_cvar_pointer("mp_timelimit");
	g_pPassword 			= get_cvar_pointer("sv_password")
	g_pGravity 				= get_cvar_pointer("sv_gravity");
	g_pAllowSpec 			= get_cvar_pointer("allow_spectators");
	g_pContact 				= get_cvar_pointer("sv_contact");
	
	g_pGagSound 			= register_cvar("amx_super_gagsound", "1");
	g_pGagBlockNameChange 	= register_cvar("amx_super_gag_block_namechange", "1");
	g_pDefaultGagTime 		= register_cvar("amx_super_gag_default_time", "600.0");
	g_pAllowSoundFix 		= register_cvar("amx_soundfix_pallow", "1");
	g_pAllowPublicSpec 		= register_cvar("allow_public_spec","1");
	g_pAdminCheck 			= register_cvar("amx_admin_check", "1");
	g_pBadAimBan			= register_cvar("amx_badaim_ban", "0");
	g_pDeadChat				= register_cvar("amx_deadchat", "1");
	
	register_concmd("amx_alltalk", 	"Cmd_AllTalk", 	ADMIN_LEVEL_A, "[1 = ON | 0 = OFF]");
	register_concmd("amx_extend", 	"Cmd_Extend", 	ADMIN_LEVEL_A, "<added time to extend> : ex. 5, if you want to extend it five more minutes.");
	register_concmd("amx_gag", 		"Cmd_Gag", 		ADMIN_LEVEL_A, "<nick, #userid or authid> <a|b|c> <time> - Flags: a = Normal Chat | b = Team Chat | c = Voicecomm");
	register_concmd("amx_ungag", 	"Cmd_Ungag", 	ADMIN_LEVEL_A, "<nick, #userid or authid>");
	register_concmd("amx_pass", 	"Cmd_Pass", 	ADMIN_PASSWORD,"<password> - sets the server's password")
	register_concmd("amx_nopass", 	"Cmd_NoPass", 	ADMIN_PASSWORD,"Removes the server's password")
	register_concmd("amx_transfer", "Cmd_Transfer", ADMIN_LEVEL_D, "<nick, #userid or authid> <CT/T/Spec> Transfers that player to the specified team");
	register_concmd("amx_swap", 	"Cmd_Swap", 	ADMIN_LEVEL_D, "<nick, #userid or authid> <nick, #userid or authid> Swaps 2 players with eachother");
	register_concmd("amx_teamswap", "Cmd_TeamSwap", ADMIN_LEVEL_D, "Swaps 2 teams with eachother");
	register_concmd("amx_lock", 	"Cmd_Lock", 	ADMIN_LEVEL_D, "<CT/T/Auto/Spec> - Locks selected team");
	register_concmd("amx_unlock",	"Cmd_Unlock",	ADMIN_LEVEL_D, "<CT/T/Auto/Spec> - Unlocks selected team");
	register_concmd("amx_badaim", 	"Cmd_BadAim", 	ADMIN_LEVEL_D, "<nick, #userid or authid> <On/off or length of time: 1|0|time> <Save?: 1|0>: Turn on/off bad aim on a player.");
	register_concmd("amx_exec", 	"Cmd_Exec", 	ADMIN_BAN, "<nick, #userid, authid or @team> <command>");
	register_concmd("amx_restart", 	"Cmd_Restart", 	ADMIN_BAN, 	   "<seconds (1-20)> - Restarts the server in seconds");
	register_concmd("amx_shutdown", "Cmd_Restart", 	ADMIN_RCON,    "<seconds (1-20)> - Shuts down the server in seconds");
	
	register_clcmd("say /gravity", "Cmd_Gravity");
	register_clcmd("say /alltalk", "Cmd_Alltalk");
	register_clcmd("say /fixsound", "Cmd_FixSound");
	register_clcmd("say /spec", "Cmd_Spec");
	register_clcmd("say /unspec", "Cmd_UnSpec");
	register_clcmd("say /admin", "Cmd_Admins");
	register_clcmd("say /admins", "Cmd_Admins");
	
	// admin voicecomm
	register_clcmd("+adminvoice", 	"Cmd_PlusAdminVoice");		
	register_clcmd("-adminvoice", 	"Cmd_MinAdminVoice");		
	register_event("VoiceMask", 	"Event_VoiceMask", "b");
	register_forward(FM_Voice_SetClientListening, "Fwd_SetClientListening");
	
	// Dead chat
	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1);
	
	// amx_gag
	register_clcmd("say", "Cmd_Say");
	register_clcmd("say_team", "Cmd_Say");
	
	// szTeam locker
	register_menucmd(register_menuid("Team_Select", 1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select");
	register_concmd("jointeam", "join_team");
	
	// amx_badaim
	register_event("DeathMsg", "Event_DeathMsg", "a", "1>0");
	register_forward(FM_PlayerPreThink, "FwdPlayerPrethink");

	// say /admin(s)
	g_iMaxPlayers = get_maxplayers();
	g_iMsgSayText = get_user_msgid("SayText");
		
	// amx_extend
#if defined MAPCYCLE
	new szMapName[35];
	get_mapname(szMapName, charsmax(szMapName));
	
	new iFile = fopen("mapcycle.txt", "rt");
	
	if(iFile)
	{
		new szData[50];
		
		g_bCyclerFile = false;
		
		while(!feof(iFile) && g_iMapsNum < MAX_MAPS)
		{
			fgets(iFile, szData, charsmax(szData));
			trim(szData);
			
			if(!szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/'))
				continue;
			
			if(equali(szData, szMapName))
			{
				g_bCyclerFile = true;
				
				break;
			}
			
			g_iMapsNum++;
		}
		
		fclose(iFile);
	}
#endif
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


/* client disconnects
 *-------------------
*/
public client_disconnect(id)
{
	g_PlayerSpk[id] = SPEAK_NORMAL2;
	ClearPlayerBit(g_iAdminBit, id);
	
	g_bHasBadAim[id] = false;
}

/* client_authorized
 *------------------
*/
public client_authorized(id) 
{ 
 	if(get_user_flags(id) & ADMIN_RESERVATION) 
		SetPlayerBit(g_iAdminBit, id);
		
	check_aimvault(id);
	
	// For amx_exec
	if(!is_user_bot(id))
		query_client_cvar(id, "cl_filterstuffcmd", "CallbackCvarQuery");
}


public CallbackCvarQuery(id, const szCvarName[], const szCvarValue[])
	g_bAllowsAllCommands[id] = szCvarValue[0] == '0' ? true : false;

/* Player Spawn
 *--------------
*/
public Fwd_PlayerSpawn_Post(id)
{
	// Dead chat
	if(is_user_alive(id) && g_iSpeak[id] != SPEAK_MUTED)
		g_iSpeak[id] = SPEAK_NORMAL;
}
/* Player death
 *-------------
*/
public Event_DeathMsg()
{
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	
	// amx_badaim
	if(g_bHasBadAim[iKiller] /*&& g_AutoBan[iKiller] */&& iKiller != iVictim)
	{
		new szName[35];
		get_user_name(iKiller, szName, charsmax(szName));
		
		if(get_pcvar_num(g_pBadAimBan))
			server_cmd("amx_ban #%i Got a kill with bad aim.", get_user_userid(iKiller));
		
		client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_KILLED", szName);
	}
	
	// Dead chat
	if(get_pcvar_num(g_pDeadChat))
	{
		if(g_iSpeak[iVictim] != SPEAK_MUTED)
			g_iSpeak[iVictim] = SPEAK_LISTENALL;
			
		client_print(iVictim, print_center, "%L", LANG_PLAYER, "AMX_SUPER_DEADCHAT_MESSAGE");
	}
	
}

/*	1)	amx_alltalk
 *-----------------
*/
public Cmd_AllTalk(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;
		
	if(read_argc() < 2)
	{	
		console_print(id, "%L", id, "AMX_SUPER_ALLTALK_STATUS", get_pcvar_num(g_pAllTalk));
		
		return PLUGIN_HANDLED;
	}
	
	new szArg[5];
	read_argv(1, szArg, charsmax(szArg));
	set_pcvar_num(g_pAllTalk, str_to_num(szArg));
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	console_print(id, "%L", id, "AMX_SUPER_ALLTALK_MSG", szArg);
		
	show_activity_key("AMX_SUPER_ALLTALK_SET_CASE1", "AMX_SUPER_ALLTALK_SET_CASE2", szAdminName, szArg);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_ALLTALK_LOG", szAdminName, szAdminAuthid, szArg);
	
	return PLUGIN_HANDLED;
}


/*	2)	amx_extend
 *----------------
*/
public Cmd_Extend(id, iLevel, iCid)
{	
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
#if defined MAPCYCLE
	if(!g_bCyclerFile)
	{
		client_print(id, print_chat, "%L", id, "AMX_SUPER_EXTEND_NOMAPCYCLE");
		
		return PLUGIN_HANDLED;
	}
#endif
	
	new szArg[35];
	read_argv(1, szArg, charsmax(szArg));
	
	new szAdminName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
		
	if(strlen(szArg))
	{
		if(containi(szArg, "-") != -1)
		{
			client_print(id,print_chat,"%L", id, "AMX_SUPER_EXTEND_BAD_NUMBER");
			
			return PLUGIN_HANDLED;
		}
		
		new iExtendTime = str_to_num(szArg);
		
		if(g_iExtendLimit++ >= EXTENDMAX)
		{
			client_print(id,print_chat,"%L", id, "AMX_SUPER_EXTEND_EXTENDMAX",EXTENDMAX);
			
			return PLUGIN_HANDLED;
		}
		
		if(iExtendTime > EXTENDTIME)
		{
			client_print(id,print_chat,"%L", id, "AMX_SUPER_EXTEND_EXTENDTIME",EXTENDTIME);
			
			iExtendTime = EXTENDTIME;
		}
		
		set_pcvar_float(g_pTimeLimit, get_pcvar_float(g_pTimeLimit) + iExtendTime);
		
		show_activity_key("AMX_SUPER_EXTEND_SUCCESS_CASE1", "AMX_SUPER_EXTEND_SUCCESS_CASE2", szAdminName, iExtendTime);
	}
	
	return PLUGIN_HANDLED;
}	


/*	3)	amx_gag	/ amx_ungag
 *-------------
*/
public Cmd_Gag(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;
	
	new szTarget[35], szFlags[5], szTime[10];
	read_argv(1, szTarget, charsmax(szTarget));
	read_argv(2, szFlags, charsmax(szFlags));
	read_argv(3, szTime, charsmax(szTime));
	
	new iPlayer = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
	
	if(iPlayer)
	{
		if (g_GagFlags[iPlayer] != NONE)
		{
			new szName[35];
			get_user_name(iPlayer, szName, charsmax(szName));
			console_print(id, "%L", id, "AMX_SUPER_ALREADY_GAGGED", szName);
			
			return PLUGIN_HANDLED
		}
		
		new Float: flGagTime;
		
		if(!strlen(szFlags))
		{
			copy(szFlags, charsmax(szFlags), "abc");
			
			flGagTime = get_pcvar_float(g_pDefaultGagTime);
		}
		
		else if(isdigit(szFlags[0])
		&& !strlen(szTime)) // he forgot the flags
		{
			flGagTime = str_to_float(szFlags) * 60;
			
			copy(szFlags, charsmax(szFlags), "abc");
		}
		
		else if(strlen(szFlags) 
		&& strlen(szTime) 
		&& isdigit(szTime[0])) {	// he entered all the args.
			flGagTime = floatstr(szTime) * 60;
		}
		
		new bool: bReasonFound;
		if(read_argc() == 4)
		{
			read_argv(4, g_szGagReason[iPlayer], 49);
			
			if(!strlen(g_szGagReason[iPlayer]))
				bReasonFound = false;
			
			else
				bReasonFound = true;
		}
		
		g_GagFlags[iPlayer] = eGagFlags:read_flags(szFlags);
		
		if(g_GagFlags[iPlayer] & VOICE)
			g_iSpeak[iPlayer] = SPEAK_MUTED;
		
		set_task(flGagTime, "TaskUngagPlayer", iPlayer + TASK_GAG);
		
		new szShownFlags[50], iFlagCount;
		if(g_GagFlags[iPlayer] & CHAT)
		{
			copy(szShownFlags, charsmax(szShownFlags), "say");
			
			iFlagCount++;
		}
		
		if(g_GagFlags[iPlayer] & TEAM_CHAT)
		{
			if(iFlagCount)
				add(szShownFlags, charsmax(szShownFlags), " / say_team");
			
			else
				copy(szShownFlags, charsmax(szShownFlags), "say_team");
			
			iFlagCount++;
		}
		
		if(g_GagFlags[iPlayer] & VOICE)
		{	
			if(iFlagCount)
				add(szShownFlags, charsmax(szShownFlags), " / voicecomm");
			
			else
				copy(szShownFlags, charsmax(szShownFlags), "voicecomm");
		}
		
		new szAdminName[35], szAdminAuthid[35];
		get_user_name(id, szAdminName, charsmax(szAdminName));
		get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
		
		new szPlayerName[35], szPlayerAuthid[35];
		get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName));
		get_user_authid(iPlayer, szPlayerAuthid, charsmax(szPlayerAuthid));
		
		if(bReasonFound)
			// These 2 keys do not exist in the language file.
			show_activity_key("AMX_SUPER_GAG_PLAYER_REASON_CASE1", "AMX_SUPER_GAG_PLAYER_REASON_CASE2", szAdminName, szPlayerName, flGagTime, szShownFlags, g_szGagReason[iPlayer]);
			
 		else
			show_activity_key("AMX_SUPER_GAG_PLAYER_CASE1", "AMX_SUPER_GAG_PLAYER_CASE2", szAdminName, szPlayerName, flGagTime, szShownFlags);	
	}
	
	return PLUGIN_HANDLED;
}

public client_infochanged(id)
{
	if(g_GagFlags[id] != NONE && get_pcvar_num(g_pGagBlockNameChange))
	{
		new szOldName[35], szNewName[35];
		get_user_name(id, szOldName, charsmax(szOldName));
		get_user_info(id, "szName", szNewName, charsmax(szNewName));
		
		if(!equal(szOldName, szNewName))
		{
			set_user_info(id, "szName", szOldName);
			
			client_print(id, print_chat, "%L", id, "AMX_SUPER_PLAYER_NAMELOCK");
		}
	}
}

public Cmd_Say(id)
{
	if(g_GagFlags[id] == NONE)
		return PLUGIN_CONTINUE;
		
	new szCmd[5];
	read_argv(0, szCmd, charsmax(szCmd));
	
	if(((g_GagFlags[id] & TEAM_CHAT) && szCmd[3] == '_') || ((g_GagFlags[id] & CHAT) && szCmd[3] != '_'))
	{
		if(g_szGagReason[id][0])
			client_print(id, print_chat, "%L", id, "AMX_SUPER_GAG_REASON", g_szGagReason[id]);
		
		else
			client_print(id, print_chat, "%L", id, "AMX_SUPER_PLAYER_GAGGED");
		
		if(get_pcvar_num(g_pGagSound))
			client_cmd(id, "spk ^"barney/youtalkmuch^"");
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Cmd_Ungag(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))	
		return PLUGIN_HANDLED;
		
	new szTarget[35];
	read_argv(1, szTarget, charsmax(szTarget));
	
	new iPlayer = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
	
	if(iPlayer)
	{
		new szPlayerName[35];
		get_user_name(id, szPlayerName, charsmax(szPlayerName));
		
		if(g_GagFlags[iPlayer] == NONE)
		{
			console_print(id, "%L", id, "AMX_SUPER_NOT_GAGGED", szPlayerName);
			return PLUGIN_HANDLED;
		}
		
		UngagPlayer(iPlayer);
		
		new szAdminName[35];
		get_user_name(id, szAdminName, charsmax(szAdminName));
		
		new szAdminAuthid[35], szPlayerAuthid[35];
		get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
		get_user_authid(iPlayer, szPlayerAuthid, charsmax(szPlayerAuthid));
		
		show_activity_key("AMX_SUPER_UNGAG_PLAYER_CASE1", "AMX_SUPER_UNGAG_PLAYER_CASE2", szAdminName, szPlayerName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UNGAG_PLAYER_LOG", szAdminName, szAdminAuthid, szPlayerName, szPlayerAuthid);
	}
	
	return PLUGIN_HANDLED;
}

public TaskUngagPlayer(id)
{
	id -= TASK_GAG;
	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	UngagPlayer(id);
	
	new szName[35];
	get_user_name(id, szName, charsmax(szName));
	
	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GAG_END", szName);

	return PLUGIN_HANDLED;
}

UngagPlayer(id)
{
	if(g_GagFlags[id] & VOICE)
	{
		if(get_pcvar_num(g_pAllTalk))
			g_iSpeak[id] = SPEAK_ALL;
		
		else
			g_iSpeak[id] = SPEAK_NORMAL;
	}
	
	if(task_exists(id + TASK_GAG))
		remove_task(id + TASK_GAG);
		
	g_GagFlags[id] = NONE;
}

/* 4)	amx_pass
 *--------------
*/
public Cmd_Pass(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED
		
	new szPassword[64]
	
	read_argv(1, szPassword, 63)
	
	new szAuthid[34]
	get_user_authid(id, szAuthid, 33)
	
	new szName[32]
	get_user_name(id, szName, 31)
	
	show_activity_key("AMX_SUPER_PASSWORD_SET_CASE1", "AMX_SUPER_PASSWORD_SET_CASE2", szName)
	
	log_amx("%L", LANG_SERVER, "AMX_SUPER_PASSWORD_SET_LOG",szName, szAuthid, szPassword)
	
	set_pcvar_string(g_pPassword, szPassword)
	
	return PLUGIN_HANDLED
}

/* 5)	amx_nopass
 *----------------
*/
public Cmd_NoPass(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED
	
	new szAuthid[34]
	get_user_authid(id, szAuthid, 33)
	
	new szName[32]
	get_user_name(id, szName, 31)
	
	show_activity_key("AMX_SUPER_PASSWORD_REMOVE_CASE1", "AMX_SUPER_PASSWORD_REMOVE_CASE2", szName)
	
	log_amx("%L", LANG_SERVER, "AMX_SUPER_PASSWORD_REMOVE_LOG",szName, szAuthid)
	
	set_pcvar_string(g_pPassword, "")
	
	return PLUGIN_HANDLED
}

/* 6)	admin voicecomm
 *---------------------
*/
public Cmd_PlusAdminVoice(id)
{
	if(!CheckPlayerBit(g_iAdminBit, id))
	{
		client_print(id, print_chat, "%L", id, "AMX_SUPER_VOCOM_NO_ACCESS");
		
		return PLUGIN_HANDLED;
	}

	client_cmd(id, "+voicerecord");
	g_PlayerSpk[id] = SPEAK_ADMIN;

	new szAdminName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));

	new iPlayers[32], iPlayerNum, iTempid;
	get_players(iPlayers, iPlayerNum, "ch");
 
	for(new i = 0; i < iPlayerNum; i++)
	{
		iTempid = iPlayers[i];
		
		if(CheckPlayerBit(g_iAdminBit, iTempid) && iTempid != id)
				client_print(iTempid, print_chat, "%L", iTempid, "AMX_SUPER_VOCOM_SPEAKING1", szAdminName);
	}
	
	client_print(id, print_chat, "%L", id, "AMX_SUPER_VOCOM_SPEAKING2", szAdminName);
	
	return PLUGIN_HANDLED;
}

public Cmd_MinAdminVoice(id) 
{
	if(is_user_connected(id)) 
	{ 
		client_cmd(id,"-voicerecord");
		
		if(g_PlayerSpk[id] == SPEAK_ADMIN) 
			g_PlayerSpk[id] = SPEAK_NORMAL2;
	}
	
	return PLUGIN_HANDLED;
}

public Event_VoiceMask(id)
	g_iVoiceMask[id] = read_data(2);
	
// Shared with amx gag.
public Fwd_SetClientListening(Reciever, Sender, listen)
{	
	if(Reciever == Sender)
		return FMRES_IGNORED;
	
	if(g_PlayerSpk[Sender] == SPEAK_ADMIN) 
	{
		if(CheckPlayerBit(g_iAdminBit, Reciever))
			engfunc(EngFunc_SetClientListening, Reciever, Sender, SPEAK_NORMAL2);
			
		else
			engfunc(EngFunc_SetClientListening, Reciever, Sender, SPEAK_MUTED2);

		return FMRES_SUPERCEDE;
	}
	
	else if(g_iVoiceMask[Reciever] & 1 << (Sender - 1)) 
	{
		engfunc(EngFunc_SetClientListening, Reciever, Sender, SPEAK_MUTED);
		
		forward_return(FMV_CELL, false);
	}
	
	switch(g_iSpeak[Reciever])
	{	
		case SPEAK_MUTED:
		{
			engfunc(EngFunc_SetClientListening, Reciever, Sender, 0);
			forward_return(FMV_CELL, 0);
			
			return FMRES_SUPERCEDE;
		}
		
		case SPEAK_ALL, SPEAK_LISTENALL:
		{
			engfunc(EngFunc_SetClientListening, Reciever, Sender, 1);
			forward_return(FMV_CELL, 1);
			
			return FMRES_SUPERCEDE;
		}
	}
		
	return FMRES_IGNORED;
}
	
/* 7)	amx_transfer
 *------------------
*/
public Cmd_Transfer(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
	
	new szTarget[35], szTeam[5];
	read_argv(1, szTarget, charsmax(szTarget));
	read_argv(2, szTeam, charsmax(szTeam));
	strtoupper(szTeam);
	
	new iTempid = cmd_target(id, szTarget, 2);
	
	if(!iTempid)
		return PLUGIN_HANDLED;
	
	new szTeamName[35];
	new CsTeams:iCurrentTeam = cs_get_user_team(iTempid)

	if(!strlen(szTeam))
	{	
		cs_set_user_team(iTempid, iCurrentTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
		formatex(szTeamName, charsmax(szTeamName), "%s", Teamnames[_:iCurrentTeam - 1]);
	}
	
	else
	{
		new CsTeams:iArgTeam
		switch(szTeam[0])
		{
			case 'C': iArgTeam = CS_TEAM_CT;
			case 'T': iArgTeam = CS_TEAM_T;
			case 'S': iArgTeam = CS_TEAM_SPECTATOR;
			default:
			{
				console_print(id, "%L", id, "AMX_SUPER_TEAM_INVALID");
				return PLUGIN_HANDLED;
			}
		}
		
		if (iArgTeam == iCurrentTeam)
		{
			console_print(id, "%L", id, "AMX_SUPER_TRANSFER_PLAYER_ALREADY")
			return PLUGIN_HANDLED
		}
		
		else
		{
			/*
			if (iArgTeam == CS_TEAM_SPECTATOR)
				user_silentkill(iTempid)
				
			cs_set_user_team(iTempid, iArgTeam)
			
			if (iArgTeam != CS_TEAM_SPECTATOR)
				ExecuteHamB(Ham_CS_RoundRespawn, iTempid)
				
			*/
			cs_set_user_team(iTempid, iArgTeam)
			
			if(iArgTeam == CS_TEAM_SPECTATOR)
				user_silentkill(iTempid);
				
			else
				ExecuteHamB(Ham_CS_RoundRespawn, iTempid);

			// using teamnames variable if szTeam != spec
			formatex(szTeamName, charsmax(szTeamName), "%s", iArgTeam == CS_TEAM_SPECTATOR ? "Spectator" : Teamnames[_:iArgTeam - 1])
		}
	}
	
	new szAdminName[35], szPlayerName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_name(iTempid, szPlayerName, charsmax(szPlayerName));
	
	new szAuthid[35];
	get_user_authid(id, szAuthid, charsmax(szAuthid));
	
	show_activity_key("AMX_SUPER_TRANSFER_PLAYER_CASE1", "AMX_SUPER_TRANSFER_PLAYER_CASE2", szAdminName, szPlayerName, szTeamName);

	client_print(iTempid, print_chat, "%L", iTempid, "AMX_SUPER_TRANSFER_PLAYER_TEAM", szTeamName);

	console_print(id, "%L", id, "AMX_SUPER_TRANSFER_PLAYER_CONSOLE", szAdminName, szTeamName);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TRANSFER_PLAYER_LOG", szAdminName, szAuthid, szPlayerName, szTeamName);
	
	return PLUGIN_HANDLED;
}
	
/* 8)	amx_swap
 *--------------
*/
public Cmd_Swap(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
		
	new szArg1[35], szArg2[35];
	read_argv(1, szArg1, charsmax(szArg1));
	read_argv(2, szArg2, charsmax(szArg2));
	
	new iTempid1 = cmd_target(id, szArg1, 2);
	new iTempid2 = cmd_target(id, szArg2, 2);
	
	if(!iTempid1 || !iTempid2)
		return PLUGIN_HANDLED;
		
	new CsTeams: iTeam1 = cs_get_user_team(iTempid1);
	new CsTeams: iTeam2 = cs_get_user_team(iTempid2);
	
	if(iTeam1 == iTeam2)
	{
		client_print(id, print_console, "%L", id, "AMX_SUPER_TRANSFER_PLAYER_ERROR_CASE1");
		
		return PLUGIN_HANDLED;
	}
	
	if(iTeam1 == CS_TEAM_UNASSIGNED || iTeam2 == CS_TEAM_UNASSIGNED)
	{
		client_print(id, print_console, "%L", id, "AMX_SUPER_TRANSFER_PLAYER_ERROR_CASE2");
		
		return PLUGIN_HANDLED;
	}
	
	cs_set_user_team(iTempid1, iTeam2);
	ExecuteHamB(Ham_CS_RoundRespawn, iTempid1);
	
	cs_set_user_team(iTempid2, iTeam1);
	ExecuteHamB(Ham_CS_RoundRespawn, iTempid2);
	
	if(iTeam1 == CS_TEAM_SPECTATOR)
		user_silentkill(iTempid2);
	
	if(iTeam2 == CS_TEAM_SPECTATOR)
		user_silentkill(iTempid1);
	
	new szPlayerName1[35], szPlayerName2[35], szAdminName[35], szAuthid[35];
	get_user_name(iTempid1, szPlayerName1, charsmax(szPlayerName1));
	get_user_name(iTempid2, szPlayerName2, charsmax(szPlayerName2));
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAuthid, charsmax(szAuthid));
	
	show_activity_key("AMX_SUPER_TRANSFER_SWAP_PLAYERS_SUCCESS_CASE1", "AMX_SUPER_TRANSFER_SWAP_PLAYERS_SUCCESS_CASE2", szAdminName, szPlayerName1, szPlayerName2);

	client_print(iTempid1, print_chat, "%L", iTempid1, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_MESSAGE1", szPlayerName2);
	client_print(iTempid2, print_chat, "%L", iTempid2, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_MESSAGE2", szPlayerName1);

	client_print(id, print_console, "%L", id, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_CONSOLE", szPlayerName1, szPlayerName2);
	
	log_amx("%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_LOG", szAdminName, szAuthid, szPlayerName1, szPlayerName2);
	
	return PLUGIN_HANDLED;
}

/* 9)	amx_teamswap
 *------------------
*/
public Cmd_TeamSwap(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;
		
	new iPlayers[32], iPlayerNum, iTempid, CsTeams: iTeam;
	get_players(iPlayers, iPlayerNum);
	
	for(new i = 0; i < iPlayerNum; i++)
	{
		iTempid = iPlayers[i];
		iTeam = cs_get_user_team(iTempid);
		
		if(CS_TEAM_UNASSIGNED < iTeam < CS_TEAM_SPECTATOR)
		{
			cs_set_user_team(iTempid, cs_get_user_team(iTempid) == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
			ExecuteHamB(Ham_CS_RoundRespawn, iTempid);
		}
	}
	
	new szName[35], szAuthid[35];
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuthid, charsmax(szAuthid));

	show_activity_key("AMX_SUPER_TRANSFER_SWAP_TEAM_SUCCESS_CASE1", "AMX_SUPER_TRANSFER_SWAP_TEAM_SUCCESS_CASE2", szName);

	console_print(id,"%L", id, "AMX_SUPER_TRANSFER_SWAP_TEAM_MESSAGE");
	
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TRANSFER_SWAP_TEAM_LOG", szName,szAuthid);
	
	return PLUGIN_HANDLED;
}

/* 10)	amx_lock
 *--------------
*/
public Cmd_Lock(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szArg[7];
	read_argv(1, szArg, charsmax(szArg));
	strtoupper(szArg);
	
	new iTeam;
	switch(szArg[0])
	{
		case 'T': iTeam = TERRO;
		case 'C': iTeam = COUNTER;		
		case 'A': iTeam = AUTO;
		case 'S': iTeam = SPEC;
		default:
		{	
			client_print(id, print_console, "%L", id, "AMX_SUPER_TEAM_INVALID");
			
			return PLUGIN_HANDLED;
		}	
	}
		
	g_bBlockJoin[iTeam] = true;
	
	new szName[35], szAuthid[35];
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuthid, charsmax(szAuthid));
	
	show_activity_key("AMX_SUPER_TEAM_LOCK_CASE1", "AMX_SUPER_TEAM_LOCK_CASE2", szName, Teamnames[iTeam]);

	console_print(id, "%L", id, "AMX_SUPER_TEAM_LOCK_CONSOLE", Teamnames[iTeam]);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_LOCK_TEAMS_LOG", szName, szAuthid, Teamnames[iTeam]);

	return PLUGIN_HANDLED;
}

/* 11)	amx_unlock
 *----------------
*/
public Cmd_Unlock(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szArg[7], iTeam;
	read_argv(1, szArg, charsmax(szArg));
	strtoupper(szArg);
	
	// comments set by juann, since we use strtoupper we don't need to check for lower case chars
	switch(szArg[0])
	{
		case 'T': iTeam = TERRO;
		case 'C': iTeam = COUNTER;
		case 'A': iTeam = AUTO;
		case 'S': iTeam = SPEC;
		default:
		{	
			client_print(id, print_console, "%L", id, "AMX_SUPER_TEAM_INVALID");
			
			return PLUGIN_HANDLED;
		}	
	}
	
	g_bBlockJoin[iTeam] = false;
	
	new szName[32], szAuthid[35];
	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuthid, charsmax(szAuthid));
	
	show_activity_key("AMX_SUPER_TEAM_UNLOCK_CASE1", "AMX_SUPER_TEAM_UNLOCK_CASE2", szName, Teamnames[iTeam]);
	
	console_print(id, "%L", id, "AMX_SUPER_TEAM_UNLOCK_CONSOLE", Teamnames[iTeam]);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_UNLOCK_TEAMS_LOG", szName, szAuthid, Teamnames[iTeam]);

	return PLUGIN_HANDLED;
}

/* Team locker
 *------------
*/
public team_select(id, key) 
{ 
	if(g_bBlockJoin[key])
	{
		engclient_cmd(id, "chooseteam");
		
		return PLUGIN_HANDLED;
	} 		
	
	return PLUGIN_CONTINUE;
} 

public join_team(id) 
{		
	new szArg[3];
	read_argv(1, szArg, charsmax(szArg));
	
	if(g_bBlockJoin[str_to_num(szArg) - 1])
	{
		engclient_cmd(id, "chooseteam");
		
		return PLUGIN_HANDLED;
	} 

	return PLUGIN_CONTINUE; 
}

/* 12)	amx_badaim
 *----------------
*/
public Cmd_BadAim(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
		
	new szTarget[35], szTime[10], szSave[2];
	
	read_argv(1, szTarget, charsmax(szTarget));
	read_argv(2, szTime, charsmax(szTime));
	read_argv(3, szSave, charsmax(szSave));
	
	if(!strlen(szTime))
	{
		console_print(id, "%L", id, "AMX_SUPER_BADAIM_CONSOLE");
		
		return PLUGIN_HANDLED;
	}
	
	new iTime = str_to_num(szTime);

	if(iTime < 0)
	{
		console_print(id, "%L", id, "AMX_SUPER_BADAIM_BADTIME");
		
		return PLUGIN_HANDLED;
	}
	
	new iTempid = cmd_target(id, szTarget, 2);

	if(!iTempid)
		return PLUGIN_HANDLED;
			
	new szName[35];
	get_user_name(iTempid, szName, charsmax(szName));
	
	switch(iTime)
	{
		case 0:
		{
			if(!g_bHasBadAim[iTempid])
			{
				console_print(id, "%L", id, "AMX_SUPER_BADAIM_NO_BADAIM", szName);
				
				return PLUGIN_HANDLED;
			}
			
			g_bHasBadAim[iTempid] = false;
			
			console_print(id, "%L", id, "AMX_SUPER_BADAIM_UNDO",szName);

			set_aimvault(iTempid, 0);
		}
		
		case 1:
		{
			if(g_bHasBadAim[iTempid])
			{
				console_print(id, "%L", id, "AMX_SUPER_BADAIM_CURRENT", szName);
				
				return PLUGIN_HANDLED;
			}
						
			g_bHasBadAim[iTempid] = true;
			
			console_print(id, "%L", id, "AMX_SUPER_BADAIM_WORSE", szName);
		}
		
		default: // Timed
		{
			if(g_bHasBadAim[iTempid])
				console_print(id, "%L", id, "AMX_SUPER_BADAIM_MESSAGE1",szName, iTime);
				
			else
				console_print(id, "%L", id, "AMX_SUPER_BADAIM_MESSAGE2",szName, iTime);
				
			g_bHasBadAim[iTempid] = true;
			
			new iTaskData[3];
			iTaskData[0] = id;
			iTaskData[1] = iTempid;
			
			set_task(float(iTime), "Task_UnBadAim", iTempid + TASKID_UNBADAIM, iTaskData, 2);
		}
	}
	
	new iSave = str_to_num(szSave);
	
	if(iSave)
	{
		if(iTime > 1)
			console_print(id, "%L", id, "AMX_SUPER_BADAIM_BAN");

		else
			set_aimvault(iTempid, 1);
	}
	
	new szPlayerName[32], szAuthid[32];
	get_user_name(id, szPlayerName, 31);
	get_user_authid(id, szAuthid, 31);

	log_amx( "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_LOG", szPlayerName, szAuthid, g_bHasBadAim[iTempid] == true? "set" : "removed", szName);
	
	return PLUGIN_HANDLED;
}

public Task_UnBadAim(iTaskData[])
{
	new id = iTaskData[0];
	new iTempid = iTaskData[1];
	
	new szName[35];
	get_user_name(iTempid, szName, charsmax(szName));

	client_print(id, print_chat, "%L", id, "AMX_SUPER_BADAIM_NO_BADAIM_MESSAGE", szName);	
	console_print(id, "%L", id, "AMX_SUPER_BADAIM_NO_BADAIM_MESSAGE_CONSOLE", szName);

	g_bHasBadAim[iTempid] = false;
}

public set_aimvault(id, iValue)
{
	new szAuthid[35];
	get_user_authid(id, szAuthid, charsmax(szAuthid));
	
	new szVaultKey[51];
	formatex(szVaultKey, charsmax(szVaultKey), "BADAIM_%s", szAuthid);

	if(vaultdata_exists(szVaultKey))
		remove_vaultdata(szVaultKey);
	
	if(iValue == 1)
		set_vaultdata(szVaultKey, "1");
}

public check_aimvault(id)
{
	new szAuthid[35];
	get_user_authid(id, szAuthid, charsmax(szAuthid));
	
	new szVaultKey[51];
	format(szVaultKey,50,"BADAIM_%s",szAuthid);

	if(vaultdata_exists(szVaultKey))
		g_bHasBadAim[id] = true;
}

public FwdPlayerPrethink(id)
{
	if(g_bHasBadAim[id])
	{
		static Float: BadAimVec[3] = {100.0, 100.0, 100.0};
		set_pev(id, pev_punchangle, BadAimVec);
	}
}


/* 13)	amx_exec
 *--------------
*/
public Cmd_Exec(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;

	new szTarget[35], szTargetName[35], szCommand[64];
	read_argv(1, szTarget, charsmax(szTarget));
	read_argv(2, szCommand, charsmax(szCommand));
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new bIsFilteredCmd = false;
	
	// Check if command is a banned one.
	for(new i = 0; i < sizeof(g_szAlwaysBlockedCmds); i++)
	{
		if(containi(szCommand, g_szAlwaysBlockedCmds[i]) > -1)
		{
			// TODO: Add ML support.
			console_print(id, "The command %s is banned and does not work on iPlayers.", szCommand);
			
			if(szTarget[0] != '@')
			{
				new iPlayer = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF);
				
				if(iPlayer)
					get_user_name(iPlayer, szTarget, charsmax(szTarget));
			}
			
			log_amx("ADMIN %s <%s> used banned command '%s' on '%s'", szAdminName, szAdminAuthid, szCommand, szTarget);
			
			return PLUGIN_HANDLED;
		}
	}
	
	// Check if the command is a filtered one.
	for(new i = 0; i < sizeof(g_szFilterStuffCmdBlockedCmds); i++)
	{
		if(containi(szCommand, g_szFilterStuffCmdBlockedCmds[i]) > -1)
		{
			bIsFilteredCmd = true;
			break;
		}
	}
	
	new iPlayer;
	
	if(szTarget[0] == '@')
	{
		new iPlayers[32], iPlayerNum, eCmdTeam: Team;
		
		switch(szTarget[1])
		{
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "e", "TERRORIST");
				
				Team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "e", "CT");
				
				Team = CT;
			}
			
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum);
				
				Team = ALL;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iPlayer = iPlayers[i];
			
			if((get_user_flags(iPlayer) & ADMIN_IMMUNITY) && iPlayer != id)
			{
				get_user_name(iPlayer, szTargetName, charsmax(szTargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
						
			else if(bIsFilteredCmd && !g_bAllowsAllCommands[iPlayer])
			{
				// TODO: Add ML support.
				get_user_name(iPlayer, szTargetName, charsmax(szTargetName));
				console_print(id, "The command %s is banned and does not work on iPlayers.", szCommand);
				continue;
			}
			
			client_cmd(iPlayer, szCommand);
		}
		
		show_activity_key("AMX_SUPER_EXEC_TEAM_CASE1", "AMX_SUPER_EXEC_TEAM_CASE2", szAdminName, szCommand, g_TeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_EXEC_TEAM_LOG", szAdminName, szAdminAuthid, szCommand, g_TeamNames[Team]);
	}
	
	else
	{
		iPlayer = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
		
		if(iPlayer)
		{
			new szTargetAuthid[35];
			get_user_name(iPlayer, szTargetName, charsmax(szTargetName));
			get_user_authid(iPlayer, szTargetAuthid, charsmax(szTargetAuthid));
			
			// TODO: Add translation for this.
			if(bIsFilteredCmd && !g_bAllowsAllCommands[iPlayer])
			{
				console_print(id, "Cannot execute command '%s' on player %s", szCommand, szTargetName);
				log_amx("ADMIN %s <%s> used banned command '%s' on '%s'", szAdminName, szAdminAuthid, szCommand, szTargetName);
			}

			else
			{
				client_cmd(iPlayer, szCommand);
			
				show_activity_key("AMX_SUPER_EXEC_PLAYER_CASE1", "AMX_SUPER_EXEC_PLAYER_CASE2", szAdminName, szCommand, szTargetName);
				log_amx("%L", LANG_SERVER, "AMX_SUPER_EXEC_PLAYER_LOG", szAdminName, szAdminAuthid, szCommand, szTargetName, szTargetAuthid);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

/* 14)	amx_restart / shutdown
 *----------------------------
*/
public Cmd_Restart(id, iLevel, iCid)
{
	if(g_bIsShuttingDown || !cmd_access(id, iLevel, iCid, 2))	
		return PLUGIN_HANDLED;
	
	new szCmd[14];
	read_argv(0, szCmd, charsmax(szCmd));
	
	if(equali(szCmd, "amx_restart"))
		g_ShutDownMode = RESTART;
	
	else
		g_ShutDownMode = SHUTDOWN;
		
	new szTime[4];
	read_argv(1, szTime, charsmax(szTime));
	
	new iTime = str_to_num(szTime);
	
	if(!(1 <= iTime <= 20))
	{
		console_print(id, "%L", id, "AMX_SUPER_SHUTDOWN_CONSOLE");
		
		return PLUGIN_HANDLED;
	}
	
	
	g_bIsShuttingDown = true;
	
	new iCount;
	for(iCount = iTime; iCount != 0; iCount--)
		set_task(float(abs(iCount - iTime)), "TaskShutDown", iCount);
	
	set_task(float(iTime), "TaskShutDown");	
	
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	show_activity_key("AMX_SUPER_SHUTDOWN_CASE1", "AMX_SUPER_SHUTDOWN_CASE2", szAdminName, g_szShutdownNames[g_ShutDownMode], iTime);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_SHUTDOWN_MESSAGE_LOG", szAdminName, id, szAdminAuthid, g_szShutdownNames[g_ShutDownMode]);
	
	return PLUGIN_HANDLED;
}

public TaskShutDown(iNumber)
{
	if(!iNumber)
	{
		if(g_ShutDownMode == RESTART)
			server_cmd("restart");
		
		else
			server_cmd("quit");
	}
	
	new szNum[32];
	num_to_word(iNumber, szNum, charsmax(szNum));
	
	client_cmd(0, "spk ^"fvox/%s^"", szNum);
}

/* 15)	say /gravity
 *------------------
*/
public Cmd_Gravity(id)
{
	client_print(id, print_chat, "%L", id, "AMX_SUPER_GRAVITY_CHECK", get_pcvar_num(g_pGravity));
	
	return PLUGIN_HANDLED;
}

/* 16)	say /alltalk
 *------------------
*/
public Cmd_Alltalk(id)
{
	client_print(id, print_chat, "%L", id, "AMX_SUPER_ALLTALK_STATUS", get_pcvar_num(g_pAllTalk));
	
	return PLUGIN_HANDLED;
}

/* 17)	say /spec
 *---------------
*/
public Cmd_Spec(id)
{
	new CsTeams: Team = cs_get_user_team(id);
	
	if(( Team == CS_TEAM_CT || Team == CS_TEAM_T ) && get_pcvar_num(g_pAllowSpec) || get_pcvar_num(g_pAllowPublicSpec)) 
	{
		if(is_user_alive(id))
		{
			user_kill(id);
			
			cs_set_user_deaths( id, cs_get_user_deaths(id) - 1);
			set_user_frags( id, get_user_frags(id) + 1);
		}
		
		g_OldTeam[id] = Team;
		
		cs_set_user_team(id, CS_TEAM_SPECTATOR);
	}

	return PLUGIN_HANDLED;
}

/* 18)	say /unspec
 *-----------------
*/
public Cmd_UnSpec(id)
{
	if(g_OldTeam[id])
	{
		cs_set_user_team(id, g_OldTeam[id]);
		g_OldTeam[id] = CS_TEAM_UNASSIGNED;
	}
	
	return PLUGIN_HANDLED;
}

/* 19)	say /admin(s)
 *-------------------
*/
public Cmd_Admins(id) 
{
	new szMessage[256];
	
	if(get_pcvar_num(g_pAdminCheck))
	{
		new szAdminNames[33][32];
		new szContactInfo[256], szContact[112];
		new i, iCount, x, iLen;
		
		for(i = 1 ;i <= g_iMaxPlayers; i++)
		{
			if(is_user_connected(i) && (get_user_flags(i) & ADMIN_CHECK))
				get_user_name(i, szAdminNames[iCount++], 31);
		}
		
		iLen = format(szMessage, 255, "%s ADMINS ONLINE: ",COLOR);
		
		if(iCount > 0) 
		{
			for(x = 0 ; x < iCount ; x++) 
			{
				iLen += format(szMessage[iLen], 255-iLen, "%s%s ", szAdminNames[x], x < (iCount-1) ? ", ":"");
				
				if(iLen > 96 ) 
				{
					print_message(id, szMessage);
					iLen = format(szMessage, 255, "%s ",COLOR);
				}
			}
			
			print_message(id, szMessage);
		}
		
		else 
		{
			iLen += format(szMessage[iLen], 255-iLen, "No admins online.");
			print_message(id, szMessage);
		}
		
		get_pcvar_string(g_pContact, szContact, 63);
		
		if(szContact[0])  
		{
			format(szContactInfo, 111, "%s Contact Server Admin -- %s", COLOR, szContact);
			print_message(id, szContactInfo);
		}
	}
	
	else
	{
		formatex(szMessage, 255, "^x04 Admin Check is currently DISABLED.");
		print_message(id, szMessage);
	}
}

print_message(id, szMsg[]) 
{		
	message_begin(MSG_ONE, g_iMsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(szMsg)
	message_end()
}

/* 20)	say /fixsound
 *-------------------
*/
public Cmd_FixSound(id)
{
	if(get_pcvar_num(g_pAllowSoundFix))
	{
		client_cmd(id, "stopsound; room_type 00");
		client_cmd(id, "stopsound");
		
		client_print(id, print_chat, "%L", id, "AMX_SUPER_SOUNDFIX");
	}
	
	else
		client_print(id, print_chat, "%L", id, "AMX_SUPER_SOUNDFIX_DISABLED");
	
	return PLUGIN_HANDLED;
} 
