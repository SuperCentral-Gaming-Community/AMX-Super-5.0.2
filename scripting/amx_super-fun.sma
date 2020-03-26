/* * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Super - Fun Commands
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
 *   AMX Super - Fun Commands (amx_super-fun.sma)
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
 
 // Fun commands

/*
 *	Nr 		COMMAND				CALLBACK FUNCTION			ADMIN LEVEL
 *	
 *	1)		amx_heal			Cmd_Heal					ADMIN_LEVEL_A		
 *	2)		amx_armor			Cmd_Armor					ADMIN_LEVEL_A
 *	3)		amx_teleport		Cmd_Teleport				ADMIN_LEVEL_A
 *	4)		amx_userorigin		Cmd_UserOrigin				ADMIN_LEVEL_A
 *	5)		amx_stack			Cmd_Stack					ADMIN_LEVEL_A
 *	6)		amx_gravity			Cmd_Gravity					ADMIN_LEVEL_A
 *	7)		amx_unammo			Cmd_UnAmmo					ADMIN_LEVEL_A
 *	8)		amx_weapon(menu)	Cmd_Weapon(Menu)			ADMIN_LEVEL_C
 *	9)		amx_drug			Cmd_Drug					ADMIN_LEVEL_C
 *	10)		amx_godmode			Cmd_Godmode					ADMIN_LEVEL_C
 *	11)		amx_setmoney		Cmd_SetMoney				ADMIN_LEVEL_C
 *	12)		amx_noclip			Cmd_Noclip					ADMIN_LEVEL_C
 *	13)		amx_speed			Cmd_Speed					ADMIN_LEVEL_C
 *	14)		amx_revive			Cmd_Revive					ADMIN_LEVEL_C
 *	15)		amx_bury			Cmd_Bury					ADMIN_LEVEL_B 	
 *	16)		amx_unbury			Cmd_Unbury					ADMIN_LEVEL_B
 *	17)		amx_disarm			Cmd_Disarm					ADMIN_LEVEL_B
 *	18)		amx_slay2			Cmd_Slay2					ADMIN_LEVEL_B
 *	19)		amx_rocket			Cmd_Rocket					ADMIN_LEVEL_B
 *	20)		amx_fire			Cmd_Fire					ADMIN_LEVEL_B
 *	21)		amx_flash			Cmd_Flash					ADMIN_LEVEL_B
 *	22)		amx_uberslap		Cmd_UberSlap				ADMIN_LEVEL_B
 *	23)		amx_glow(2)			Cmd_Glow					ADMIN_LEVEL_D
 *	24)		amx_glowcolors		Cmd_GlowColors				ADMIN_LEVEL_D
*/ 


#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31))) 

// amx_disarm
#define OFFSET_PRIMARYWEAPON        116 

// amx_glow & amx_glow2
#define MAX_COLORS 	30


// 	Used for the show_activity() / log_amx messages.
enum CmdTeam
{
	ALL,
	T,
	CT
};

new const g_szTeamNames[CmdTeam][] = 
{ 
	"all",
	"Terrorist", 
	"Counter-Terrorist" 
};


// cvar pointers
new g_pGravity;
// new g_pMaxSpeed;
new g_pAllowCatchFire;
new g_pFlashSound;

// perm checks
enum (<<=1) 
{
	PERMGOD = 1,
	PERMSPEED,
	PERMDRUGS,
	PERMNOCLIP,
	HASSPEED,
	HASGLOW
};
new g_iFlags[33];


// amx_weaponmenu
new g_iTeamMenu, g_iPlayerMenu;

// amx_speed
new bool: g_bIsFreezeTime;

// amx_fire
new g_iOnFireBit;

// amx_userorigin
new g_iUserOrigin[33][3];

// amx_unammo
new g_iUnammoBit, Float: g_iReloadTime[33];

// amx_glow, amx_glow2, amx_glowcolors
new const g_iColorValues[MAX_COLORS][3] = 
{
	{255, 0, 0},
	{255, 190, 190},
	{165, 0, 0},
	{255, 100, 100},
	{0, 0, 255},
	{0, 0, 136},
	{95, 200, 255},
	{0, 150, 255},
	{0, 255, 0},
	{180, 255, 175},
	{0, 155, 0},
	{150, 63, 0},
	{205, 123, 64},
	{255, 255, 255},
	{255, 255, 0},
	{189, 182, 0},
	{255, 255, 109},
	{255, 150, 0},
	{255, 190, 90},
	{222, 110, 0},
	{243, 138, 255},
	{255, 0, 255},
	{150, 0, 150},
	{100, 0, 100},
	{200, 0, 0},
	{220, 220, 0},
	{192, 192, 192},
	{190, 100, 10},
	{114, 114, 114},
	{0, 0, 0}
};

new const g_szColorNames[MAX_COLORS][] = 
{
	"red",
	"pink",
	"darkred",
	"lightred",
	"blue",
	"darkblue",
	"lightblue",
	"aqua",
	"green",
	"lightgreen",
	"darkgreen",
	"brown",
	"lightbrown",
	"white",
	"yellow",
	"darkyellow",
	"lightyellow",
	"orange",
	"lightorange",
	"darkorange",
	"lightpurple",
	"purple",
	"darkpurple",
	"violet",
	"maroon",
	"gold",
	"silver",
	"bronze",
	"grey",
	"off"
};
new g_iGlowColors[33][4];

// sprites for effects
new g_iSmokeSpr, g_iWhiteSpr, g_iLightSpr, g_iBlueflare2Spr, g_iMflashSpr;

// message ids
new g_iMsgDamage, g_iMsgScreenFade, g_iMsgSetFOV;


public plugin_init()
{
	register_plugin("Amx Super Fun", "5.0.2", "SuperCentral.co");
	register_dictionary("amx_super.txt");
	
	register_concmd("amx_heal", 		"Cmd_Heal", 		ADMIN_LEVEL_A, "<nick, #userid, authid or @team> <HP to give>");
	register_concmd("amx_armor", 		"Cmd_Armor", 		ADMIN_LEVEL_A, "<nick, #userid, authid or @team> <armor to give>");
	register_concmd("amx_teleport", 	"Cmd_Teleport", 	ADMIN_LEVEL_A, "<nick, #userid or authid> [x] [y] [z]");
	register_concmd("amx_userorigin", 	"Cmd_UserOrigin", 	ADMIN_LEVEL_A, "<nick, #userid or authid>");
	register_concmd("amx_stack", 		"Cmd_Stack", 		ADMIN_LEVEL_A, "<nick, #userid or authid> [0|1|2]");
	register_concmd("amx_gravity", 		"Cmd_Gravity", 		ADMIN_LEVEL_A, "<gravity #>");
	register_concmd("amx_unammo", 		"Cmd_UnAmmo", 		ADMIN_LEVEL_A, "<nick, #userid or @team> [0|1] - 0=OFF 1=ON");
	register_concmd("amx_weaponmenu", 	"Cmd_WeaponMenu", 	ADMIN_LEVEL_C, "shows the weapon menu");
	register_concmd("amx_weapon", 		"Cmd_Weapon", 		ADMIN_LEVEL_C, "<nick, #userid or @team> <weapon #>");
	register_concmd("amx_drug", 		"Cmd_Drug", 		ADMIN_LEVEL_C, "<@all, @team, nick, #userid, authid> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND");
	register_concmd("amx_godmode", 		"Cmd_Godmode", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND");
	register_concmd("amx_setmoney",		"Cmd_SetMoney",		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> <amount> - sets specified player's money");
	register_concmd("amx_money", 		"Cmd_SetMoney", 	ADMIN_LEVEL_C, "<nick, #userid, authid or @team> <amount> - sets specified player's money");
	register_concmd("amx_noclip", 		"Cmd_Noclip", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND");
	register_concmd("amx_speed", 		"Cmd_Speed", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND");
	register_concmd("amx_revive", 		"Cmd_Revive", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team>");
	register_concmd("amx_bury", 		"Cmd_Bury", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_unbury", 		"Cmd_Unbury",		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_disarm",		"Cmd_Disarm", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_slay2", 		"Cmd_Slay2",		ADMIN_LEVEL_B, "<nick, #userid, authid or @team> [1-Lightning|2-Blood|3-Explode]");
	register_concmd("amx_rocket", 		"Cmd_Rocket", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_fire", 		"Cmd_Fire", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_flash", 		"Cmd_Flash", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team");
	register_concmd("amx_uberslap", 	"Cmd_UberSlap", 	ADMIN_LEVEL_B, "<nick, #userid or authid");
	register_concmd("amx_glow", 		"Cmd_Glow", 		ADMIN_LEVEL_D, "<nick, #userid, authid, or @team/@all> <color> (or) <rrr> <ggg> <bbb> <aaa> -- lasts 1 round");
	register_concmd("amx_glow2", 		"Cmd_Glow", 		ADMIN_LEVEL_D, "<nick, #userid, authid, or @team/@all> <color> (or) <rrr> <ggg> <bbb> <aaa> -- lasts forever");
	register_concmd("amx_glowcolors", 	"Cmd_GlowColors", 	ADMIN_LEVEL_D, "shows a list of colors for amx_glow and amx_glow2");
	
	// Register new cvars and get existing cvar pointers:
	g_pGravity 			= get_cvar_pointer("sv_gravity");
	// g_pMaxSpeed 		= get_cvar_pointer("sv_maxspeed");
	
	g_pAllowCatchFire 	= register_cvar("allow_catchfire", "1");
	g_pFlashSound 		= register_cvar("amx_flashsound","1");
	
	// amx_unammo
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
		
	// amx_weaponmenu
	g_iTeamMenu = menu_create("\rTeam?", "TeamHandler");
	menu_additem(g_iTeamMenu, "All", "1");
	menu_additem(g_iTeamMenu, "Counter-Terrorist", "2");
	menu_additem(g_iTeamMenu, "Terrorist", "3");
	menu_additem(g_iTeamMenu, "Player", "4");
	g_iPlayerMenu = menu_create("\rPlayers:", "PlayerHandler");
	
	// amx_drug
	g_iMsgSetFOV = get_user_msgid("SetFOV");
	
	// amx_speed
	RegisterHam(Ham_Item_PreFrame, "player", "FwdPlayerSpeedPost", 1);
	register_logevent("LogEventRoundStart", 2, "1=Round_Start");
	register_event("HLTV", "EventFreezeTime", "a");
	/*
		DREKES:
		set_pcvar_num() doesn't seem to take effect here.
		server_cmd() does.
	*/
	// set_pcvar_num(g_pMaxSpeed, 9999999);
	server_cmd("sv_maxspeed 999999");
	
	// message ids
	g_iMsgDamage = get_user_msgid("Damage");
	g_iMsgScreenFade = get_user_msgid("ScreenFade");
	
	// Used by several commands
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1);
}

/* Precache
 *---------
*/
public plugin_precache()
{
	// amx_slay2 & amx_rocket sprites
	g_iSmokeSpr 		= precache_model("sprites/steam1.spr");
	g_iWhiteSpr		= precache_model("sprites/white.spr");
	g_iLightSpr 		= precache_model("sprites/lgtning.spr");
	g_iBlueflare2Spr 	= precache_model( "sprites/blueflare2.spr");
	g_iMflashSpr 		= precache_model("sprites/muzzleflash.spr");
	
	// amx_rocket sounds
	precache_sound("ambience/thunder_clap.wav");
	precache_sound("weapons/headshot2.wav");
	precache_sound("weapons/rocketfire1.wav");
	precache_sound("weapons/rocket1.wav");
	
	// amx_fire sounds
	precache_sound("ambience/flameburst1.wav");
	precache_sound("scientist/scream21.wav");
	precache_sound("scientist/scream07.wav");
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

/* Player Spawn
 *-------------
*/
public FwdPlayerSpawnPost(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;
		
	if(g_iFlags[id] & PERMDRUGS)
		set_user_drugs(id, 1);
		
	if(g_iFlags[id] & PERMGOD)
		set_user_godmode(id, 1);
	
	if(g_iFlags[id] & PERMNOCLIP)
		set_user_noclip(id, 1);
		
	if(g_iFlags[id] & PERMSPEED)
		SetSpeed(id, 2);
	
	else if(g_iFlags[id] & HASSPEED)
	{
		g_iFlags[id] &= ~HASSPEED;
		SetSpeed(id, 0);
	}
	
	if(g_iFlags[id] & HASGLOW)
		set_user_rendering(id, kRenderFxGlowShell, g_iGlowColors[id][0], g_iGlowColors[id][1], g_iGlowColors[id][2], kRenderTransAlpha, g_iGlowColors[id][3]);	
	else
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		
	return HAM_IGNORED;
}


/* Player Disconnects
 *-------------------
*/
public client_disconnect(id)
{
	if(CheckPlayerBit(g_iOnFireBit, id))
		ClearPlayerBit(g_iOnFireBit, id);
		
	g_iFlags[id] = 0;
}


/*	1)	amx_heal
 *--------------
*/
public Cmd_Heal(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
	
	new szArg[35], szHealth[10];
	read_argv(1, szArg, charsmax(szArg));
	read_argv(2, szHealth, charsmax(szHealth));
	
	new iHealth = str_to_num(szHealth);
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid, szTargetName[35];
	
	if(iHealth <= 0)	
	{
		console_print(id, "%L", id, "AMX_SUPER_AMOUNT_GREATER");
		
		return PLUGIN_HANDLED;
	}
	
	if(szArg[0] == '@')
	{
		new iPlayers[32], iPlayersNum, CmdTeam: Team;
		
		switch(szArg[1])
		{
			case 'T', 't':
			{	
				get_players(iPlayers, iPlayersNum, "ae", "TERRORIST");
				
				Team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayersNum, "ae", "CT");
				
				Team = CT;
			}
			
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayersNum, "a");
				
				Team = ALL;
			}
		}
		
		if(!iPlayersNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}

		for(new i = 0; i < iPlayersNum; i++)
			set_user_health(iPlayers[i], iHealth);
		
		show_activity_key("AMX_SUPER_HEAL_TEAM_CASE1", "AMX_SUPER_HEAL_TEAM_CASE2", szAdminName, iHealth, g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_HEAL_TEAM_LOG", szAdminName, szAdminAuthid, iHealth, g_szTeamNames[Team]);
	}
	
	else
	{	
		iTempid = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			set_user_health(iTempid, iHealth);
			
			new szTargetAuthid[35];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			show_activity_key("AMX_SUPER_HEAL_PLAYER_CASE1", "AMX_SUPER_HEAL_PLAYER_CASE2", szAdminName, iHealth, szTargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_HEAL_PLAYER_LOG", szAdminName, szAdminAuthid, iHealth, szTargetName, szTargetAuthid);
		}
	}

	return PLUGIN_HANDLED;
}


/* 2)	amx_armor
 *---------------
*/
public Cmd_Armor(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
	
	new szArg[35], szArmor[10];
	read_argv(1, szArg, charsmax(szArg));
	read_argv(2, szArmor, charsmax(szArmor));
	
	new iArmor = str_to_num(szArmor);
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid, szTargetName[35];
	
	if(iArmor <= 0)	
	{
		console_print(id, "%L", id, "AMX_SUPER_AMOUNT_GREATER");
		
		return PLUGIN_HANDLED;
	}
	
	if(szArg[0] == '@')
	{
		new iPlayers[32], iPlayersNum, CmdTeam: Team;
		
		switch(szArg[1])
		{
			case 'T', 't':
			{	
				get_players(iPlayers, iPlayersNum, "ae", "TERRORIST");
				
				Team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayersNum, "ae", "CT");
				
				Team = CT;
			}
			
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayersNum, "a");
				
				Team = ALL;
			}
		}
		
		if(!iPlayersNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}

		for(new i = 0; i < iPlayersNum; i++)
			cs_set_user_armor(iPlayers[i], iArmor, CS_ARMOR_VESTHELM);
		
		show_activity_key("AMX_SUPER_ARMOR_TEAM_CASE1", "AMX_SUPER_ARMOR_TEAM_CASE2", szAdminName, iArmor, g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ARMOR_TEAM_LOG", szAdminName, szAdminAuthid, iArmor, g_szTeamNames[Team]);
	}
	
	else
	{	
		iTempid = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			cs_set_user_armor(iTempid, iArmor, CS_ARMOR_VESTHELM);
			
			new szTargetAuthid[35];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			show_activity_key("AMX_SUPER_ARMOR_PLAYER_CASE1", "AMX_SUPER_ARMOR_PLAYER_CASE2", szAdminName, iArmor, szTargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_ARMOR_PLAYER_LOG", szAdminName, szAdminAuthid, iArmor, szTargetName, szTargetAuthid);
		}
	}

	return PLUGIN_HANDLED;
}


/* 3)	amx_teleport
 *------------------
*/
public Cmd_Teleport(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 5))
		return PLUGIN_HANDLED;
	
	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new iTempid = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	
	if(iTempid)
	{
		new szOrigin1[5], szOrigin2[5], szOrigin3[5];
		read_argv(2, szOrigin1, charsmax(szOrigin1));
		read_argv(3, szOrigin2, charsmax(szOrigin2));
		read_argv(4, szOrigin3, charsmax(szOrigin3));
		
		new Float: flOrigin[3];
		flOrigin[0] = str_to_float(szOrigin1);
		flOrigin[1] = str_to_float(szOrigin2);
		flOrigin[2] = str_to_float(szOrigin3);
		
		engfunc(EngFunc_SetOrigin, iTempid, flOrigin);
		
		new szAdminName[35], szAdminAuthid[35];
		get_user_name(id, szAdminName, charsmax(szAdminName));
		get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
		
		new szTargetName[35], szTargetAuthid[35];
		get_user_name(iTempid, szTargetName, charsmax(szTargetName));
		get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
		
		show_activity_key("AMX_SUPER_TELEPORT_PLAYER_CASE1", "AMX_SUPER_TELEPORT_PLAYER_CASE2", szAdminName, szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_TELEPORT_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid, floatround(flOrigin[0]), floatround(flOrigin[1]), floatround(flOrigin[2]));
	}
	
	return PLUGIN_HANDLED;
}

/* 4)	amx_userorigin
 *--------------------
*/
public Cmd_UserOrigin(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2)) 
		return PLUGIN_HANDLED;

	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));

	new iTempid = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
	
	if(iTempid)
	{
		new szTargetName[35];
		get_user_origin(iTempid, g_iUserOrigin[id]);
		get_user_name(iTempid, szTargetName, charsmax(szTargetName));

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TELEPORT_ORIGIN_SAVED", g_iUserOrigin[id][0], g_iUserOrigin[id][1], g_iUserOrigin[id][2], szTargetName);
	}
	
	return PLUGIN_HANDLED;
}

/* 5)	amx_stack
 *---------------
*/
public Cmd_Stack(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;

	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));

	new iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	
	if(iTempid)
	{	
		new szType[5];
		read_argv(2, szType, charsmax(szType));
		
		new Float: flOrigin[3];
		pev(iTempid, pev_origin, flOrigin);

		new iYAxis = 36, iZAxis = 96;
		switch(str_to_num(szType))
		{
			case 0: iYAxis = 0;
			case 1: iZAxis = 0;
		}
	
		new iPlayers[32], iPlayerNum, iPlayer;
		get_players(iPlayers, iPlayerNum, "a");
		
		for(new i = 0; i < iPlayerNum ; i++)
		{
			iPlayer = iPlayers[i];
			
			if((iPlayer == id) || (get_user_flags(iPlayer) & ADMIN_IMMUNITY) && iPlayer != id) 
				continue;
				
			flOrigin[1] += iYAxis;
			flOrigin[2] += iZAxis;
			set_pev(iPlayer, pev_origin, flOrigin);
		}

		new szAdminName[35], szAdminAuthid[35];
		get_user_name(id, szAdminName, charsmax(szAdminName));
		get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
		
		new szTargetName[35], szTargetAuthid[35];
		get_user_name(iTempid, szTargetName, charsmax(szTargetName));
		get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_STACK_PLAYER_MSG", szTargetName);
		
		show_activity_key("AMX_SUPER_STACK_PLAYER_CASE1", "AMX_SUPER_STACK_PLAYER_CASE2", szAdminName, szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_STACK_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
	}

	return PLUGIN_HANDLED;
}

/*	6)	amx_gravity
 *-----------------
*/
public Cmd_Gravity(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))	
		return PLUGIN_HANDLED;
	
	if(read_argc() < 2)
	{
		console_print(id, "%L", id, "AMX_SUPER_GRAVITY_STATUS", get_pcvar_num(g_pGravity));
		
		return PLUGIN_HANDLED;
	}
	
	new szArg[5];
	read_argv(1, szArg, charsmax(szArg));
	set_pcvar_num(g_pGravity, str_to_num(szArg));
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	console_print(id, "%L", id, "AMX_SUPER_GRAVITY_MSG", szArg);
	
	show_activity_key("AMX_SUPER_GRAVITY_SET_CASE1", "AMX_SUPER_GRAVITY_SET_CASE2", szAdminName, szArg);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_GRAVITY_LOG", szAdminName, szAdminAuthid, szArg);
	
	return PLUGIN_HANDLED;
}

/* 7)	amx_unammo
 *----------------
*/
public Cmd_UnAmmo(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szArg1[35], szArg2[5];
	read_argv(1, szArg1, charsmax(szArg1));
	read_argv(2, szArg2, charsmax(szArg2));
	
	new iSetting = str_to_num(szArg2);
	
	new szAdminName[35], szAdminAuthid[35];
	new szTargetName[35];
	
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid;
	if(szArg1[0] == '@')
	{
		new CmdTeam: Team, iPlayers[32], iPlayerNum;
		
		switch(szArg1[1])
		{
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				Team = T;
			}
			
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				Team = ALL;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				Team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && iTempid != id)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				console_print(id, "%L", "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			if(iSetting)
				SetPlayerBit(g_iUnammoBit, iTempid);
			
			else
				ClearPlayerBit(g_iUnammoBit, iTempid);
		}
		
		console_print(id, "%L", id, "AMX_SUPER_AMMO_TEAM_MSG", g_szTeamNames[Team], iSetting);
		
		show_activity_key("AMX_SUPER_AMMO_CASE1", "AMX_SUPER_AMMO_CASE2", szAdminName, g_szTeamNames[Team], iSetting);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_AMMO_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[Team], iSetting);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{	
			if(iSetting)
				SetPlayerBit(g_iUnammoBit, iTempid);
			
			else
				ClearPlayerBit(g_iUnammoBit, iTempid);
				
			new szTargetAuthid[35];
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			
			console_print(id, "%L", id, "AMX_SUPER_AMMO_PLAYER_MSG", szTargetName, iSetting);
			
			show_activity_key("AMX_SUPER_AMMO_PLAYER_CASE1", "AMX_SUPER_AMMO_PLAYER_CASE2", szAdminName, szTargetName, iSetting);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_AMMO_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid, iSetting);
		}
	}
	
	return PLUGIN_HANDLED;
}

public Event_CurWeapon(id)
{
	if(CheckPlayerBit(g_iUnammoBit, id))
	{
		new iWeaponid = read_data(2);
		new iClip = read_data(3);
	
		if(iWeaponid == CSW_C4 
		|| iWeaponid == CSW_KNIFE
		|| iWeaponid == CSW_HEGRENADE
		|| iWeaponid == CSW_SMOKEGRENADE
		|| iWeaponid == CSW_FLASHBANG) {
			return PLUGIN_CONTINUE;
		}
		
		if(!iClip)
		{
			new iSystime = get_systime();
			
			if(g_iReloadTime[id] >= iSystime - 1)
				return PLUGIN_CONTINUE;
			
			new szWeaponName[20];
			get_weaponname(iWeaponid, szWeaponName, charsmax(szWeaponName));
			
			new EntId = -1;
			while((EntId = engfunc(EngFunc_FindEntityByString, EntId, "classname", szWeaponName)) != 0)
			{	
				if(pev_valid(EntId) && pev(EntId, pev_owner) == id)
				{
					cs_set_weapon_ammo(EntId, getMaxClipAmmo(iWeaponid));
					
					break;
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

getMaxClipAmmo(iWeaponid)
{
	new iClip = -1;
	
	switch(iWeaponid)
	{
		case CSW_P228: iClip = 13;
		case CSW_SCOUT, CSW_AWP: iClip = 10;
		case CSW_HEGRENADE, CSW_C4, CSW_SMOKEGRENADE, CSW_FLASHBANG, CSW_KNIFE: iClip = 0;
		case CSW_XM1014, CSW_DEAGLE: iClip = 7;
		case CSW_MAC10, CSW_AUG, CSW_SG550, CSW_MP5NAVY, CSW_M4A1, CSW_SG552, CSW_AK47: iClip = 30;
		case CSW_ELITE: iClip = 15;
		case CSW_FIVESEVEN, CSW_GLOCK18, CSW_G3SG1: iClip = 20;
		case CSW_UMP45, CSW_FAMAS: iClip = 25;
		case CSW_GALI: iClip = 35;
		case CSW_USP: iClip = 12;
		case CSW_M249: iClip = 100;
		case CSW_M3: iClip = 8;
		case CSW_P90: iClip = 50;
	}
	
	return iClip;
}		

/* 8a)	amx_weapon
 *----------------
*/
enum
{
	WEAPON_USP,
	WEAPON_GLOCK18,
	WEAPON_DEAGLE,
	WEAPON_P228,
	WEAPON_ELITE,
	WEAPON_FIVESEVEN,
	WEAPON_M3,
	WEAPON_XM1014,
	WEAPON_TMP,
	WEAPON_MAC10,
	WEAPON_MP5NAVY,
	WEAPON_P90,
	WEAPON_UMP45,
	WEAPON_FAMAS,
	WEAPON_GALIL,
	WEAPON_AK47,
	WEAPON_M4A1,
	WEAPON_SG552,
	WEAPON_AUG,
	WEAPON_SCOUT,
	WEAPON_SG550,
	WEAPON_AWP,
	WEAPON_G3SG1,
	WEAPON_M249,
	WEAPON_HEGRENADE,
	WEAPON_SMOKEGRENADE,
	WEAPON_FLASHBANG,
	WEAPON_SHIELD,
	WEAPON_C4,
	WEAPON_KNIFE,
	ITEM_KEVLAR,
	ITEM_ASSAULTSUIT,
	ITEM_THIGHPACK
};

new bpammo[] =  // 0 denotes a blank weapon id
{
	0,
	52,
	0,
	90,
	1,
	32,
	1,
	100,
	90,
	1,
	120,
	100,
	100,
	90,
	90,
	90,
	100,
	120,
	30,
	120,
	200,
	32,
	90,
	120,
	90,
	2,
	35,
	90,
	90,
	0,
	100
};
	
	

new g_szWeapons[33][] =
{
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle",
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_p90",
	"weapon_ump45",
	"weapon_famas",
	"weapon_galil",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_sg552",
	"weapon_aug",
	"weapon_scout",
	"weapon_sg550",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_m249",
	"weapon_hegrenade",
	"weapon_smokegrenade",
	"weapon_flashbang",
	"weapon_shield",
	"weapon_c4",
	"weapon_knife",
	"item_kevlar",
	"item_assaultsuit",
	"item_thighpack"
};

new g_szWeaponNames[][] = 
{
	"All Weapons",
	"Knife",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"Glock",
	"USP",
	"P228",
	"Deagle",
	"Fiveseven",
	"Dual Elites",
	"",
	"",
	"",
	"",
	"M3",
	"XM1014",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"TMP",
	"MAC10",
	"MP5 Navy",
	"P90",
	"UMP45",
	"",
	"",
	"",
	"",
	"Famas",
	"Galil",
	"AK47",
	"M4A1",
	"SG552",
	"AUG",
	"Scout",
	"SG550",
	"Awp",
	"G3SG1",
	"",
	"M249",
	"Kevlar and Helmit", //82
	"HE Grenade",
	"Flashbang",
	"Smoke Grenade",
	"Defuse Kit",
	"Shield",
	"",
	"",
	"",
	"C4",
	"Night Vision"
};

public Cmd_Weapon(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
	
	new szAdminName[32];
	get_user_name(id, szAdminName, 31);
	
	new szAdminAuthid[36];
	get_user_authid(id, szAdminAuthid, 35);
	
	new szArg1[32];
	read_argv(1, szArg1, 31);
	
	new szArg2[24];
	read_argv(2, szArg2, 23);
	
	new iWeapon = str_to_num(szArg2);
	
	if(szArg1[0] == '@')
	{	
		new iPlayers[32], iPlayerNum, CmdTeam: Team;
		
		
		switch(szArg1[1])
		{
			case 't', 'T':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(iPlayers, iPlayerNum, "a");
				Team = ALL;
			}
		}
		
		for(new i; i < iPlayerNum; i++)
			give_weapon(iPlayers[i], iWeapon);
					
		show_activity_key("AMX_SUPER_WEAPON_TEAM_CASE1", "AMX_SUPER_WEAPON_TEAM_CASE2", szAdminName, g_szTeamNames[Team]);

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_WEAPON_TEAM_MSG", iWeapon, g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_WEAPON_TEAM_LOG", szAdminName, szAdminAuthid, iWeapon, g_szTeamNames[Team]);
	}
	
	else
	{
		new iPlayer = cmd_target(id, szArg1, 7);
		if(!iPlayer)
			return PLUGIN_HANDLED;
			
		give_weapon(iPlayer, iWeapon);
		
		new szTargetName[32];
		get_user_name(iPlayer, szTargetName, 31);
		
		new szTargetAuthid[36];
		get_user_authid(iPlayer, szTargetAuthid, 35);
		
		show_activity_key("AMX_SUPER_WEAPON_PLAYER_CASE1", "AMXX_SUPER_WEAPON_PLAYER_CASE2", szAdminName, szTargetName);

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_PLAYER_MSG", iWeapon, szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_WEAPON_PLAYER_LOG", szAdminName, szAdminAuthid, iWeapon, szTargetName, szTargetAuthid);
	}
	
	return PLUGIN_HANDLED;
}

/* 8b)	amx_weaponmenu
 *--------------------
*/
enum 
{ 
	All,
	Ct,
	Terro,
	Player
};

new gTeamChoice[33]
	, gPlayerName[33][34]
	, gPlayerId[33]
;

public Cmd_WeaponMenu(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;

	menu_display(id, g_iTeamMenu);
	return PLUGIN_HANDLED;
}

public CmdCallbackMenu(id)
	menu_display(id, g_iTeamMenu);

public TeamHandler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
		return PLUGIN_HANDLED;

	switch(iItem)
	{
		case 0:
			gTeamChoice[id] = All;
		
		case 1:
			gTeamChoice[id] = Ct;
		
		case 2:
			gTeamChoice[id]  = Terro;
		
		case 3:
			gTeamChoice[id] = Player;
	}
	
	if(gTeamChoice[id] != Player)
		WeaponMenu(id);
		
	else
		PlayerMenu(id);
	
	return PLUGIN_HANDLED;
}

public PlayerMenu(id)
{
	new szName[34], szId[6];
	new iPlayers[32], iPlayerNum, iTempid;
	get_players(iPlayers, iPlayerNum, "a");
	for(new i; i < iPlayerNum; i++)
	{
		iTempid = iPlayers[i];
		
		get_user_name(iTempid, szName, 33);
		num_to_str(iTempid, szId, 5);
			
		menu_additem(g_iPlayerMenu, szName, szId);
	}
	
	menu_display(id, g_iPlayerMenu);
}

public PlayerHandler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		CmdCallbackMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new szInfo[6];
	new iAccess, iCallback;
	menu_item_getinfo(iMenu, iItem, iAccess, szInfo, 5, gPlayerName[id], 33, iCallback);
	
	gPlayerId[id] = str_to_num(szInfo);
	
	WeaponMenu(id);
	return PLUGIN_HANDLED;
}
	
public WeaponMenu(id)
{
	new szTitle[64], iMenu;
	
	switch(gTeamChoice[id])
	{	
		case All: 
			formatex(szTitle, charsmax(szTitle), "\rTeam: All Weapon ?");
		
		case Ct:
			formatex(szTitle, charsmax(szTitle), "\rTeam: CT Weapon ?");
		
		case Terro:
			formatex(szTitle, charsmax(szTitle), "\rTeam: T Weapon ?");
			
		case Player:
			formatex(szTitle, charsmax(szTitle), "\rPlayer: %s Weapon?", gPlayerName[id]);
	}
	
	iMenu = menu_create(szTitle, "WeaponHandler");
	
	new szInfo[6];
	for(new i; i < sizeof(g_szWeaponNames); i++)
	{
		if(strlen(g_szWeaponNames[i]))
		{
			num_to_str(i, szInfo, 5);
		
			menu_additem(iMenu, g_szWeaponNames[i], szInfo);
		}
	}
	
	menu_display(id, iMenu);
}

public WeaponHandler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		CmdCallbackMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new szName[32], szInfo[6];
	new iAccess, iCallback;
	menu_item_getinfo(iMenu, iItem, iAccess, szInfo, 5, szName, 31, iCallback);
	
	new iChoice = str_to_num(szInfo);
	
	if(gTeamChoice[id] == Player)
	{
		switch(iChoice)
		{
			case 1..51:
				give_weapon(gPlayerId[id], iChoice);
			
			case 52..62:
				give_weapon(gPlayerId[id], (iChoice+30));
			
			default:
				give_weapon(gPlayerId[id], 200);
		}
	}
	
	else
	{
		new iPlayers[32], iPlayerNum;

		switch(gTeamChoice[id])
		{
			case All:
				get_players(iPlayers, iPlayerNum, "a");
			
			case Terro:
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
			
			case Ct:
				get_players(iPlayers, iPlayerNum, "ae", "CT");
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			switch(iChoice)
			{
				case 1..51:
					give_weapon(iPlayers[i], iChoice);
				
				case 52..62:
					give_weapon(iPlayers[i], (iChoice + 30));
				
				default: 
					give_weapon(iPlayers[i], 200);
			}
		}
	}
	
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

give_weapon(id,iWeapon)
{
	switch (iWeapon)
	{
		//Secondary g_szWeapons
		//Pistols
		case 1:
		{
			give_item(id,g_szWeapons[WEAPON_KNIFE]);
		}
		
		case 11:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_GLOCK18]);
		}
		
		case 12:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_USP]);
		}
		
		case 13:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_P228]);
		}
		
		case 14:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_DEAGLE]);
		}
		
		case 15:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_FIVESEVEN]);
		}
		
		case 16:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_ELITE]);
		}
		
		case 17:
		{
			//all pistols
			give_weapon(id,11);
			give_weapon(id,12);
			give_weapon(id,13);
			give_weapon(id,14);
			give_weapon(id,15);
			give_weapon(id,16);
		}
		
		//Primary g_szWeapons
		//Shotguns
		case 21:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_M3]);
		}
		
		case 22:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_XM1014]);
		}
		
		//SMGs
		case 31:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_TMP]);
		}
		
		case 32:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_MAC10]);
		}
		
		case 33:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_MP5NAVY]);
		}
		
		case 34:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_P90]);
		}
		
		case 35:
		{ 
			give_weapon_x(id, g_szWeapons[WEAPON_UMP45]);
		}
		
		//Rifles 
		case 40:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_FAMAS]);
		}
		
		case 41:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_GALIL]);
		}
		
		case 42:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_AK47]);
		}
		
		case 43:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_M4A1]);
		}
		
		case 44:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_SG552]);
		}
		
		case 45:
		{
			give_weapon_x(id,g_szWeapons[WEAPON_AUG]);
		}
		
		case 46:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_SCOUT]);
		}
		
		case 47:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_SG550]);
		}
		
		case 48:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_AWP]);
		}
		
		case 49:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_G3SG1]);
		}
		
		//Machine gun (M249 Para)
		case 51:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_M249]);
		}
		
		//Shield combos
		case 60:
		{
			give_item(id, g_szWeapons[WEAPON_SHIELD]);
			give_weapon_x(id, g_szWeapons[WEAPON_GLOCK18]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		case 61:
		{
			give_item(id, g_szWeapons[WEAPON_SHIELD]);
			give_weapon_x(id, g_szWeapons[WEAPON_USP]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		case 62:
		{
			give_item(id, g_szWeapons[WEAPON_SHIELD]);
			give_weapon_x(id, g_szWeapons[WEAPON_P228]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		case 63:
		{
			give_item(id, g_szWeapons[WEAPON_SHIELD]);
			give_weapon_x(id, g_szWeapons[WEAPON_DEAGLE]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		case 64:
		{
			give_item(id, g_szWeapons[WEAPON_SHIELD]);
			give_weapon_x(id, g_szWeapons[WEAPON_FIVESEVEN]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		//Equipment 
		case 81:
		{
			give_item(id, g_szWeapons[ITEM_KEVLAR]);
		}
		
		case 82:
		{
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		case 83:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
		}
		
		case 84:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
		}
		
		case 85:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_SMOKEGRENADE]);
		}
		
		case 86:
		{
			give_item(id, g_szWeapons[ITEM_THIGHPACK]);
		}
		
		case 87:
		{
			give_item(id, g_szWeapons[WEAPON_SHIELD]);
		}
		
		//All ammo
		case 88:
		{
			new iWeapons[32], WeaponNum;

			get_user_weapons(id, iWeapons, WeaponNum);
			for(new i; i < WeaponNum; i++) 
				cs_set_user_bpammo(id, iWeapons[i], bpammo[iWeapons[i]]);

		}
		
		//All grenades
		case 89:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_SMOKEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
		}
		
		//C4
		case 91:
		{
			give_item(id, g_szWeapons[WEAPON_C4]);
			cs_set_user_plant(id, 1, 1);
		}
		
		case 92:
		{
			cs_set_user_nvg(id, 1);
		}
		
		//AWP Combo.
		case 100:
		{
			give_weapon_x(id, g_szWeapons[WEAPON_AWP]);
			give_weapon_x(id, g_szWeapons[WEAPON_DEAGLE]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
			give_weapon_x(id, g_szWeapons[WEAPON_SMOKEGRENADE]);
			give_item(id, g_szWeapons[ITEM_ASSAULTSUIT]);
		}
		
		//Money case.
 		case 160:
		{
			cs_set_user_money(id, 16000, 1);
		}
		
		//AllWeapons
		case 200:
		{
			//all up to wpnindex 51 are given.. replace w loop
			give_weapon_x(id, g_szWeapons[WEAPON_USP]);
			give_weapon_x(id, g_szWeapons[WEAPON_GLOCK18]);
			give_weapon_x(id, g_szWeapons[WEAPON_DEAGLE]);
			give_weapon_x(id, g_szWeapons[WEAPON_P228]);
			give_weapon_x(id, g_szWeapons[WEAPON_ELITE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FIVESEVEN]);
			give_weapon_x(id, g_szWeapons[WEAPON_M3]);
			give_weapon_x(id, g_szWeapons[WEAPON_XM1014]);
			give_weapon_x(id, g_szWeapons[WEAPON_TMP]);
			give_weapon_x(id, g_szWeapons[WEAPON_MAC10]);
			give_weapon_x(id, g_szWeapons[WEAPON_MP5NAVY]);
			give_weapon_x(id, g_szWeapons[WEAPON_P90]);
			give_weapon_x(id, g_szWeapons[WEAPON_UMP45]);
			give_weapon_x(id, g_szWeapons[WEAPON_FAMAS]);
			give_weapon_x(id, g_szWeapons[WEAPON_GALIL]);
			give_weapon_x(id, g_szWeapons[WEAPON_AK47]);
			give_weapon_x(id, g_szWeapons[WEAPON_M4A1]);
			give_weapon_x(id, g_szWeapons[WEAPON_SG552]);
			give_weapon_x(id, g_szWeapons[WEAPON_AUG]);
			give_weapon_x(id, g_szWeapons[WEAPON_SCOUT]);
			give_weapon_x(id, g_szWeapons[WEAPON_SG550]);
			give_weapon_x(id, g_szWeapons[WEAPON_AWP]);
 			give_weapon_x(id, g_szWeapons[WEAPON_G3SG1]);
			give_weapon_x(id, g_szWeapons[WEAPON_M249]);
			give_weapon_x(id, g_szWeapons[WEAPON_HEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_SMOKEGRENADE]);
			give_weapon_x(id, g_szWeapons[WEAPON_FLASHBANG]);
		}
		
		default: return false;
	}
	
	return true;
}

stock give_weapon_x(id, const szWeapon[])
{
	give_item(id, szWeapon);
	
	new iWeaponid = get_weaponid(szWeapon);
	
	if(iWeaponid)
		cs_set_user_bpammo(id, iWeaponid, bpammo[iWeaponid]);
}


/* 9)	amx_drug
 *--------------
*/
public Cmd_Drug(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szArg1[24];
	read_argv(1, szArg1, 23);
	
	new szLength[6];
	read_argv(2, szLength, 2);
	
	new szAdminName[32], szAdminAuthid[32];
	get_user_name( id, szAdminName, 31 );
	get_user_authid( id, szAdminAuthid, 31 );
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, iPlayer, CmdTeam: Team;

		switch(szArg1[1])
		{
			case 't', 'T':	
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(iPlayers, iPlayerNum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iPlayer = iPlayers[i];
			
			if((get_user_flags(iPlayer) & ADMIN_IMMUNITY) && iPlayer != id)
			{
				get_user_name(iPlayer, szArg1, charsmax(szArg1));
				console_print(id, "%L", "AMX_SUPER_TEAM_IMMUNITY", szArg1);
				
				continue;
			}
			
			set_user_drugs(iPlayers[i], str_to_num(szLength));
		}
		


		show_activity_key("AMX_SUPER_DRUG_TEAM_CASE1", "AMX_SUPER_DRUG_TEAM_CASE2", szAdminName, g_szTeamNames[Team]);

		console_print( id, "%L", id, "AMX_SUPER_DRUG_TEAM_MSG", g_szTeamNames[Team]);
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_DRUG_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[Team]);
	}
	
	else
	{
		new iPlayer = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(!iPlayer)
			return PLUGIN_HANDLED;

		set_user_drugs(iPlayer, str_to_num(szLength));
		
		new szTargetName[32], szTargetAuthid[32];
		get_user_name( iPlayer, szTargetName, 31 );
		get_user_authid( iPlayer, szTargetAuthid, 31 );

		show_activity_key("AMX_SUPER_DRUG_PLAYER_CASE1", "AMX_SUPER_DRUG_PLAYER_CASE2", szAdminName, szTargetName);

		console_print( id, "%L", id, "AMX_SUPER_DRUG_PLAYER_MSG", szTargetName );
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_DRUG_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid );
	}
	
	return PLUGIN_HANDLED;
}

set_user_drugs(id, x)
{
	switch(x)
	{
		case 1,2:
		{
			message_begin(MSG_ONE, g_iMsgSetFOV, _, id);
			write_byte(180);
			message_end();
			
			if (x == 2)
				g_iFlags[id] |= PERMDRUGS;
		}

		default:
		{
			message_begin(MSG_ONE, g_iMsgSetFOV, _, id);
			write_byte(90);
			message_end();
			
			g_iFlags[id] &= ~PERMDRUGS;
		}
	}
}

/*	10)		amx_godmode
 *---------------------
*/
public Cmd_Godmode(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szAdminName[32];
	get_user_name(id, szAdminName, 31);
	
	new szAdminAuthid[36];
	get_user_authid(id, szAdminAuthid, 35);
	
	new szArg1[24];
	read_argv(1, szArg1, 23);
	
	new szLength[6];
	read_argv(2, szLength, 2);
	
	new iGodmodeFlags = str_to_num(szLength);
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, iTempid, CmdTeam: Team;
		
		switch(szArg1[1])
		{
			case 't', 'T':	
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(iPlayers, iPlayerNum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if(!iGodmodeFlags)
				g_iFlags[iTempid] &= ~PERMGOD;
				
			else if(iGodmodeFlags == 2)
				g_iFlags[iTempid] |= PERMGOD;
				
			set_user_godmode(iTempid, !!iGodmodeFlags);
			
		}

		show_activity_key("AMX_SUPER_GODMODE_TEAM_CASE1", "AMX_SUPER_GODMODE_TEAM_CASE2", szAdminName, iGodmodeFlags, g_szTeamNames[Team]);

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_TEAM_MSG", iGodmodeFlags, g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GODMODE_TEAM_LOG", szAdminName, szAdminAuthid, iGodmodeFlags, g_szTeamNames[Team]);
	}
	
	else
	{
		new iPlayer = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(!iPlayer)
			return PLUGIN_HANDLED;

		new szTargetName[32], szTargetAuthid[35];
		get_user_name(iPlayer, szTargetName, 31);
		get_user_authid(iPlayer, szTargetAuthid, charsmax(szTargetAuthid));
		
		set_user_godmode(iPlayer, !!iGodmodeFlags);
		
		if(!iGodmodeFlags)
			g_iFlags[iPlayer] &= ~PERMGOD;
			
		else if (iGodmodeFlags == 2)
			g_iFlags[iPlayer] |= PERMGOD;

		show_activity_key("AMX_SUPER_GODMODE_PLAYER_CASE1", "AMX_SUPER_GODMODE_PLAYER_CASE2", szAdminName, iGodmodeFlags, szTargetName);

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_PLAYER_MSG", iGodmodeFlags, szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GODMODE_PLAYER_LOG", szAdminName, szAdminAuthid, iGodmodeFlags, szTargetName, szTargetAuthid);
	}
	
	return PLUGIN_HANDLED;
}

/* 11)	amx_setmoney
 *-------------------
*/

// TODO: UPDATE ALL NON-EN ML STRINGS
public Cmd_SetMoney(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
	
	new szAdminAuthid[36];
	get_user_authid(id, szAdminAuthid, 35);
	
	new szAdminName[32];
	get_user_name(id, szAdminName, 31);
	
	new szArg1[32];
	read_argv(1, szArg1, 31);
	
	new szArg2[32];
	read_argv(2, szArg2, 31);
	
	new iMoney = str_to_num(szArg2);
	if(iMoney > 16000)
		iMoney = 16000;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, CmdTeam: Team;
		
		switch(szArg1[1])
		{
			case 't', 'T':	
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(iPlayers, iPlayerNum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < iPlayerNum; i++)				
			cs_set_user_money(iPlayers[i], iMoney);
	
		show_activity_key("AMX_SUPER_GIVEMONEY_TEAM_CASE1", "AMX_SUPER_GIVEMONEY_TEAM_CASE2", szAdminName, g_szTeamNames[Team], iMoney);
		
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_TEAM_MSG", g_szTeamNames[Team], iMoney);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GIVEMONEY_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[Team], iMoney);
	}
	
	else
	{
		new iPlayer = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
		if(!iPlayer)
			return PLUGIN_HANDLED;
		
		cs_set_user_money(iPlayer, iMoney);
		
		new szTargetName[32];
		get_user_name(iPlayer, szTargetName, 31);
		
		new szTargetAuthid[36];
		get_user_authid(iPlayer, szTargetAuthid, 35);
		
		show_activity_key("AMX_SUPER_GIVEMONEY_PLAYER_CASE1", "AMX_SUPER_GIVEMONEY_PLAYER_CASE2", szAdminName, szTargetName, iMoney);
		
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_PLAYER_MSG", szTargetName, iMoney);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GIVEMONEY_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid, iMoney);
	}
	
	return PLUGIN_HANDLED;
}

/* 12)	amx_noclip
 *----------------
*/
public Cmd_Noclip(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szAdminName[32];
	get_user_name(id, szAdminName, 31);
	
	new szAdminAuthid[36];
	get_user_authid(id, szAdminAuthid, 35);
	
	new szArg1[24];
	read_argv(1, szArg1, 23);
	
	new szLength[6];
	read_argv(2, szLength, 2);
	
	new iSetting = str_to_num(szLength);
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, iTempid, CmdTeam: Team;
	
		switch(szArg1[1])
		{
			case 't', 'T':	
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(iPlayers, iPlayerNum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
						
			if(!iSetting)
				g_iFlags[iTempid] &= ~PERMNOCLIP;
				
			else if (iSetting == 2)
				g_iFlags[iTempid] |= PERMNOCLIP;
				
			set_user_noclip(iTempid, !!iSetting);

		}
				
		show_activity_key("AMX_SUPER_NOCLIP_TEAM_CASE1", "AMX_SUPER_NOCLIP_TEAM_CASE2", szAdminName, iSetting, g_szTeamNames[Team]);
		
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_TEAM_MSG", iSetting, g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_NOCLIP_TEAM_LOG", szAdminName, szAdminAuthid, iSetting, g_szTeamNames[Team]);
	}
	else
	{
		new iPlayer = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		if(!iPlayer)
			return PLUGIN_HANDLED;

		new szTargetName[32];
		get_user_name(iPlayer, szTargetName, 31);
		
		new szTargetAuthid[36];
		get_user_authid(iPlayer, szTargetAuthid, 35);

		set_user_noclip(iPlayer, !!iSetting);
		
		if(!iSetting)
			g_iFlags[iPlayer] &= ~PERMNOCLIP;
			
		else if (iSetting == 2)
			g_iFlags[iPlayer] |= PERMNOCLIP;

		
		show_activity_key("AMX_SUPER_NOCLIP_PLAYER_CASE1", "AMX_SUPER_NOCLIP_PLAYER_CASE2", szAdminName, iSetting, szTargetName);

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_PLAYER_MSG",iSetting, szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_NOCLIP_PLAYER_LOG", szAdminName, szAdminAuthid, iSetting, szTargetName, szTargetAuthid);
	}
	
	return PLUGIN_HANDLED;
}

/* 13)	amx_speed
 *---------------
*/
public LogEventRoundStart()
	g_bIsFreezeTime = false;

public EventFreezeTime()
	g_bIsFreezeTime = true;
	
public FwdPlayerSpeedPost(id)
{
	if(!g_bIsFreezeTime && (g_iFlags[id] & HASSPEED) || (g_iFlags[id] & PERMSPEED))
		SetSpeed(id, 1);
}
		
public Cmd_Speed(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szAdminName[32];
	get_user_name(id, szAdminName, 31);
	
	new szAdminAuthid[36];
	get_user_authid(id, szAdminAuthid, 35);
	
	new szArg1[24];
	read_argv(1, szArg1, 23);
	
	new szLength[6];
	read_argv(2, szLength, 2);
	
	new iSpeedFlag = str_to_num(szLength);
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, CmdTeam: Team;
		
		switch(szArg1[1])
		{
			case 't', 'T':	
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(iPlayers, iPlayerNum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < iPlayerNum; i++)
			SetSpeed(iPlayers[i], iSpeedFlag);
		
		show_activity_key("AMX_SUPER_SPEED_TEAM_CASE1", "AMX_SUPER_SPEED_TEAM_CASE2", szAdminName, iSpeedFlag, g_szTeamNames[Team]);

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_TEAM_MSG", iSpeedFlag, g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SPEED_TEAM_LOG", szAdminName, szAdminAuthid, iSpeedFlag, g_szTeamNames[Team]);
	}
	else
	{
		new iPlayer = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		if(!iPlayer)
			return PLUGIN_HANDLED;
			
		new szTargetName[32];
		get_user_name(iPlayer, szTargetName, 31);
		
		SetSpeed(iPlayer, iSpeedFlag);

		show_activity_key("AMX_SUPER_SPEED_PLAYER_CASE1", "AMX_SUPER_SPEED_PLAYER_CASE2", szAdminName, iSpeedFlag, szTargetName);

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_PLAYER_MSG", iSpeedFlag, szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SPEED_PLAYER_LOG", szAdminName, szAdminAuthid, iSpeedFlag, szTargetName);
	}
	
	return PLUGIN_HANDLED;
}

SetSpeed(id, iSetting)
{
	if(!iSetting)
	{
		// Provided by ConnorMcLeod from cs_reset_user_maxspeed function in some of his plugns
		new Float:flMaxSpeed;
		
		switch ( get_user_weapon(id) )
		{
			case CSW_SG550, CSW_AWP, CSW_G3SG1 : flMaxSpeed = 210.0;
			case CSW_M249 : flMaxSpeed = 220.0;
			case CSW_AK47 : flMaxSpeed = 221.0;
			case CSW_M3, CSW_M4A1 : flMaxSpeed = 230.0;
			case CSW_SG552 : flMaxSpeed = 235.0;
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS : flMaxSpeed = 240.0;
			case CSW_P90 : flMaxSpeed = 245.0;
			case CSW_SCOUT : flMaxSpeed = 260.0;
			default : flMaxSpeed = 250.0;
		}
		set_user_maxspeed(id, flMaxSpeed);
		
		g_iFlags[id] &= ~HASSPEED;
		g_iFlags[id] &= ~PERMSPEED;
	}
	
	else
	{
		new iFlag = iSetting == 2 ? PERMSPEED : HASSPEED;
		g_iFlags[id] |= iFlag;
			
		set_user_maxspeed(id, (get_user_maxspeed(id) * 2.0));
	}
}

/* 14)	amx_revive
 *----------------
*/
public Cmd_Revive(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szArg1[24];
	read_argv(1, szArg1, 23);
	
	new szAdminName[34];
	get_user_name(id, szAdminName, 33);
	
	new szAdminAuthid[36];
	get_user_authid(id, szAdminAuthid, 35);
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, iPlayer, CmdTeam: Team;
		get_players(iPlayers, iPlayerNum);

		switch(szArg1[1])
		{
			case 't', 'T': Team = T;
			case 'c', 'C': Team = CT;
			case 'a', 'A': Team = ALL;
		}		
		
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iPlayer = iPlayers[i];
			
			switch(Team)
			{
				case T:
				{
					if(cs_get_user_team(iPlayer) == CS_TEAM_T)
						ExecuteHamB(Ham_CS_RoundRespawn, iPlayer);
				}
				
				case CT:
				{
					if(cs_get_user_team(iPlayer) == CS_TEAM_CT)
						ExecuteHamB(Ham_CS_RoundRespawn, iPlayer);
				}
				
				case ALL:
				{
					if(CS_TEAM_UNASSIGNED < cs_get_user_team(iPlayer) < CS_TEAM_SPECTATOR)
						ExecuteHamB(Ham_CS_RoundRespawn, iPlayer);
				}
			}
		}
		
		show_activity_key("AMX_SUPER_REVIVE_TEAM_CASE1", "AMX_SUPER_REVIVE_TEAM_CASE2", szAdminName, g_szTeamNames[Team]);
	
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_TEAM_MSG", g_szTeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_REVIVE_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[Team]);
	}
	else
	{
		new iPlayer = cmd_target(id, szArg1, CMDTARGET_ALLOW_SELF);
		if(!iPlayer || !(CS_TEAM_UNASSIGNED < cs_get_user_team(iPlayer) < CS_TEAM_SPECTATOR))
			return PLUGIN_HANDLED;

		ExecuteHamB(Ham_CS_RoundRespawn, iPlayer);
		
		new szTargetName[34];
		get_user_name(iPlayer, szTargetName, 33);
		
		new szTargetAuthid[36];
		get_user_authid(iPlayer, szTargetAuthid, 35);
		
		show_activity_key("AMX_SUPER_REVIVE_PLAYER_CASE1", "AMX_SUPER_REVIVE_PLAYER_CASE2", szAdminName, szTargetName);
		
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_PLAYER_MSG", szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_REVIVE_PLAYER_LOG",szAdminName, szTargetAuthid, szTargetName, szTargetAuthid);
	}
	
	return PLUGIN_HANDLED;
}

/* 15)	amx_bury
 *--------------
*/
public Cmd_Bury(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szArg1[32];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new szTargetName[32];
	
	new szAdminName[32];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	
	new szAdminAuthid[25];
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
		
	new iTempid;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, CmdTeam: team;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && iTempid != id)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
				
			BuryPlayer(iTempid);
		}
		
		show_activity_key("AMX_SUPER_BURY_TEAM_CASE1", "AMX_SUPER_BURY_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		
		log_amx("%L", LANG_SERVER, "AMX_SUPER_BURY_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			BuryPlayer(iTempid);
			
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			
			new szTargetAuthid[25];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_BURY_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			show_activity_key("AMX_SUPER_BURY_PLAYER_CASE1", "AMX_SUPER_BURY_PLAYER_CASE2", szAdminName, szTargetName);

			console_print(id, "%L", id, "AMX_SUPER_BURY_MSG", szTargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}

BuryPlayer(iTempid)
{
	new szVictimName[32];
	get_user_name(iTempid, szVictimName, charsmax(szVictimName));
	
	new iWeapons[32], iWeapon;
	get_user_weapons(iTempid, iWeapons, iWeapon);
	
	new szWeaponName[32];
	for(new i = 0; i < iWeapon; i++)
	{
		get_weaponname(iWeapons[i], szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iTempid, "drop", szWeaponName);
	}
	
	engclient_cmd(iTempid, "weapon_knife");
	
	new Float: flOrigin[3];
	pev(iTempid, pev_origin, flOrigin);
	
	flOrigin[2] -= 30.0;
	engfunc(EngFunc_SetOrigin, iTempid, flOrigin);
}

/*	16)		amx_unbury
 *--------------------
*/
public Cmd_Unbury(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szArg1[32];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new szTargetName[32];
	
	new szAdminName[32];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	
	new szAdminAuthid[25];
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
		
	new iTempid;
	
	if(szArg1[0] == '@')
	{	
		new iPlayers[32], iPlayerNum, CmdTeam: team;
	
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{			
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && iTempid != id)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			UnburyPlayer(iTempid);
		}
			
		show_activity_key("AMX_SUPER_UNBURY_TEAM_CASE1", "AMX_SUPER_UNBURY_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UNBURY_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			UnburyPlayer(iTempid);
			
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			
			
			new szTargetAuthid[25];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));

			log_amx("%L", LANG_SERVER, "AMX_SUPER_UNBURY_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			show_activity_key("AMX_SUPER_UNBURY_PLAYER_CASE1", "AMX_SUPER_UNBURY_PLAYER_CASE2", szAdminName, szTargetName);
			
			console_print(id, "%L", id, "AMX_SUPER_UNBURY_MSG", szTargetName);
			
		}
	}

	return PLUGIN_HANDLED;
}

UnburyPlayer(iTempid)
{
	new szVictimName[32];
	get_user_name(iTempid, szVictimName, charsmax(szVictimName));
	
	new Float: flOrigin[3];
	pev(iTempid, pev_origin, flOrigin);
	
	flOrigin[2] += 35.0;
	engfunc(EngFunc_SetOrigin, iTempid, flOrigin);
}

/* 17)	amx_disarm
 *----------------
*/
public Cmd_Disarm(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;

	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new szAdminName[35], szTargetName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	
	new szAdminAuthid[35];
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, CmdTeam: team;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && iTempid != id)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			strip_user_weapons(iTempid);
			set_pdata_int(iTempid, OFFSET_PRIMARYWEAPON, 0);		// Bugfix.
			give_item(iTempid, "weapon_knife");
		}
			
		show_activity_key("AMX_SUPER_DISARM_TEAM_CASE1", "AMX_SUPER_DISARM_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_DISARM_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			strip_user_weapons(id);
			set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0);
			give_item(id, "weapon_knife");
			
			new szTargetAuthid[25];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));

			log_amx("%L", LANG_SERVER, "AMX_SUPER_DISARM_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			show_activity_key("AMX_SUPER_DISARM_PLAYER_CASE1", "AMX_SUPER_DISARM_PLAYER_CASE2", szAdminName, szTargetName);

			console_print(id, "%L", id, "AMX_SUPER_DISARM_MSG", szTargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}

/* 18)	amx_slay2
 *---------------
*/
public Cmd_Slay2(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szArg1[35], szSetting[2];
	
	new szAdminName[35], szTargetName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	
	new szAdminAuthid[35];
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid, CmdTeam: team;
	
	read_argv(1, szArg1, charsmax(szArg1));
	read_argv(2, szSetting, charsmax(szSetting));
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && iTempid != id)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			slay_player(iTempid, str_to_num(szSetting));
		}
			
		show_activity_key("AMX_SUPER_SLAY2_TEAM_CASE1", "AMX_SUPER_SLAY2_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SLAY2_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			slay_player(iTempid, str_to_num(szSetting));
			
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			
			new szTargetAuthid[25];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_SLAY2_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			show_activity_key("AMX_SUPER_SLAY2_PLAYER_CASE1", "AMX_SUPER_SLAY2_PLAYER_CASE2", szAdminName, szTargetName);
			
			console_print(id, "%L", id, "AMX_SUPER_SLAY2_PLAYER_MSG", szTargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}

slay_player(iVictim,type)
{
	new iOrigin[3];
	get_user_origin(iVictim, iOrigin);

	iOrigin[2] -= 26;

	switch(type)
	{
		case 1:
		{
			new iSourceOrigin[3];
			iSourceOrigin[0] = iOrigin[0] + 150;
			iSourceOrigin[1] = iOrigin[1] + 150;
			iSourceOrigin[2] = iOrigin[2] + 400;
			lightning(iSourceOrigin, iOrigin);
			
			emit_sound(iVictim,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
		case 2:
		{
			blood(iOrigin);
			emit_sound(iVictim,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		case 3: 
			explode(iOrigin);
	}
	
	user_kill(iVictim, 1);
}

explode(iOrigin[3]) 
{
	//Blast Circles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin);
	write_byte(21);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 16);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 1936);
	write_short(g_iWhiteSpr);
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(2); // life
	write_byte(16); // width
	write_byte(0); // noise
	write_byte(188); // r
	write_byte(220); // g
	write_byte(255); // b
	write_byte(255); //brightness
	write_byte(0); // speed
	message_end();

	//Explosion2
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(12);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_byte(188); // byte (scale in 0.1's)
	write_byte(10); // byte (framerate)
	message_end();

	//Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin);
	write_byte(5);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(g_iSmokeSpr);
	write_byte(2);
	write_byte(10);
	message_end();
}

blood(iOrigin[3]) 
{
	//LAVASPLASH
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(10);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	message_end();
}

lightning (iOrigin[3],iOrigin2[3]) 
{
	//Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(0);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_coord(iOrigin2[0]);
	write_coord(iOrigin2[1]);
	write_coord(iOrigin2[2]);
	write_short(g_iLightSpr);
	write_byte(1); // framestart
	write_byte(5); // framerate
	write_byte(2); // life
	write_byte(20); // width
	write_byte(30); // noise
	write_byte(200); // r, g, b
	write_byte(200); // r, g, b
	write_byte(200); // r, g, b
	write_byte(200); // brightness
	write_byte(200); // speed
	message_end();

	//Sparks
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin2);
	write_byte(9);
	write_coord(iOrigin2[0]);
	write_coord(iOrigin2[1]);
	write_coord(iOrigin2[2]);
	message_end();

	//Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin2);
	write_byte(5);
	write_coord(iOrigin2[0]);
	write_coord(iOrigin2[1]);
	write_coord(iOrigin2[2]);
	write_short(g_iSmokeSpr);
	write_byte(10);
	write_byte(10);
	message_end();
}

/* 19)	amx_rocket
 *----------------
*/
new g_iRocketZAxis[33];

public Cmd_Rocket(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;
		
	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new szAdminName[35], szTargetName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum, CmdTeam: team;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && id != iTempid)
			{	
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			emit_sound(iTempid, CHAN_WEAPON , "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			set_user_maxspeed(iTempid,0.01);
			
			set_task(1.2, "Task_Rocket_LiftOff" , iTempid);
		}
		
		console_print(id, "%L", id, "AMX_SUPER_ROCKET_TEAM_MSG", g_szTeamNames[team]);
		
		show_activity_key("AMX_SUPER_ROCKET_TEAM_CASE1", "AMX_SUPER_ROCKET_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ROCKET_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			emit_sound(iTempid, CHAN_WEAPON, "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			set_user_maxspeed(iTempid, 0.01);
			
			set_task(1.2, "Task_Rocket_LiftOff", iTempid);
			
			new szTargetAuthid[35];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
						
			show_activity_key("AMX_SUPER_ROCKET_PLAYER_CASE1", "AMX_SUPER_ROCKET_PLAYER_CASE2", szAdminName, szTargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_ROCKET_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			
			console_print(id, "%L", id, "AMX_SUPER_ROCKET_PLAYER_MSG", szTargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}
		
public Task_Rocket_LiftOff(iVictim)
{
	if(!is_user_alive(iVictim))
		return;
		
	set_user_gravity(iVictim, -0.50);
	client_cmd(iVictim, "+jump;wait;wait;-jump");
	emit_sound(iVictim, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM);
	
	rocket_effects(iVictim);
}

public rocket_effects(iVictim)
{
	if(!is_user_alive(iVictim)) 
		return;

	new iOrigin[3];
	get_user_origin(iVictim,iOrigin);

	message_begin(MSG_ONE, g_iMsgDamage, {0,0,0}, iVictim);
	write_byte(30); // dmg_save
	write_byte(30); // dmg_take
	write_long(1<<16); // visibleDamageBits
	write_coord(iOrigin[0]); // damageOrigin.x
	write_coord(iOrigin[1]); // damageOrigin.y
	write_coord(iOrigin[2]); // damageOrigin.z
	message_end();

	if(g_iRocketZAxis[iVictim] == iOrigin[2]) 
		rocket_explode(iVictim);

	g_iRocketZAxis[iVictim] = iOrigin[2];

	//Draw Trail and effects

	//TE_SPRITETRAIL - line of moving glow sprites with gravity, fadeout, and collisions
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(15);
	write_coord(iOrigin[0]); // coord, coord, coord (start)
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_coord(iOrigin[0]); // coord, coord, coord (end)
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] - 30);
	write_short(g_iBlueflare2Spr); // short (sprite index)
	write_byte(5); // byte (count)
	write_byte(1); // byte (life in 0.1's)
	write_byte(1);  // byte (scale in 0.1's)
	write_byte(10); // byte (velocity along vector in 10's)
	write_byte(5);  // byte (randomness of velocity in 10's)
	message_end();

	//TE_SPRITE - additive sprite, plays 1 cycle
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(17);
	write_coord(iOrigin[0]);  // coord, coord, coord (position)
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] - 30);
	write_short(g_iMflashSpr); // short (sprite index)
	write_byte(15); // byte (scale in 0.1's)
	write_byte(255); // byte (brightness)
	message_end();

	set_task(0.2, "rocket_effects", iVictim);
}

public rocket_explode(iVictim)
{
	if(is_user_alive(iVictim)) 
	{
		new iOrigin[3];
		get_user_origin(iVictim, iOrigin);

		// blast circles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin);
		write_byte(21);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2] - 10);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2] + 1910);
		write_short(g_iWhiteSpr);
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(2); // life
		write_byte(16); // width
		write_byte(0); // noise
		write_byte(188); // r
		write_byte(220); // g
		write_byte(255); // b
		write_byte(255); //brightness
		write_byte(0); // speed
		message_end();

		//Explosion2
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(12);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_byte(188); // byte (scale in 0.1's)
		write_byte(10); // byte (framerate)
		message_end();

		//smoke
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin);
		write_byte(5);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(g_iSmokeSpr);
		write_byte(2);
		write_byte(10);
		message_end();

		user_kill(iVictim, 1);
	}

	//stop_sound
	emit_sound(iVictim, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, (1<<5), PITCH_NORM);

	set_user_maxspeed(iVictim, 1.0);
	set_user_gravity(iVictim, 1.00);
}

/* 20)	amx_fire
 *--------------
*/
public Cmd_Fire(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;
		
	new szAdminName[35], szAdminAuthid[35], szTargetName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new iTempid;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum;
		new CmdTeam: team;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && id != iTempid)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
		
			SetPlayerBit(g_iOnFireBit, iTempid);
			
			ignite_effects(iTempid);
			ignite_player(iTempid);
		}
		
		show_activity_key("AMX_SUPER_FIRE_TEAM_CASE1", "AMX_SUPER_FIRE_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FIRE_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			new szTargetAuthid[35];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			SetPlayerBit(g_iOnFireBit, iTempid);
			
			ignite_effects(iTempid);
			ignite_player(iTempid);
		
			show_activity_key("AMX_SUPER_FIRE_PLAYER_CASE1", "AMX_SUPER_FIRE_PLAYER_CASE2", szAdminName, szTargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_FIRE_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			
			console_print(id, "%L", id, "AMX_SUPER_FIRE_PLAYER_MSG", szTargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}
	
public ignite_effects(id)  
{
	if(is_user_alive(id) && CheckPlayerBit(g_iOnFireBit, id))
    {
		new iOrigin[3];
		get_user_origin(id, iOrigin);
		
		//TE_SPRITE - additive sprite, plays 1 cycle
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(iOrigin[0]);  // coord, coord, coord (position)
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(g_iMflashSpr); // short (sprite index)
		write_byte(20); // byte (scale in 0.1's)
		write_byte(200); // byte (brightness)
		message_end();
		
		//Smoke
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
		write_byte(5);
		write_coord(iOrigin[0]);// coord coord coord (position)
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(g_iSmokeSpr);// short (sprite index)
		write_byte(20); // byte (scale in 0.1's)
		write_byte(15); // byte (framerate)
		message_end();
		
		set_task(0.2, "ignite_effects", id);
	}
	
	else    
	{
		if(CheckPlayerBit(g_iOnFireBit, id))
		{
			emit_sound(id, CHAN_AUTO, "scientist/scream21.wav", 0.6, ATTN_NORM, 0, PITCH_HIGH);
			ClearPlayerBit(g_iOnFireBit, id);
		}
	}
}

public ignite_player(id)   
{
	if(is_user_alive(id) && CheckPlayerBit(g_iOnFireBit, id)) 
	{
		new iIdOrigin[3];
				
		new iHealth = get_user_health(id);
		get_user_origin(id, iIdOrigin);
		
		//create some damage
		set_user_health(id, iHealth - 10);
		
		message_begin(MSG_ONE, g_iMsgDamage, _, id);
		write_byte(30); // dmg_save
		write_byte(30); // dmg_take
		write_long(1<<21); // visibleDamageBits
		write_coord(iIdOrigin[0]); // damageOrigin.x
		write_coord(iIdOrigin[1]); // damageOrigin.y
		write_coord(iIdOrigin[2]); // damageOrigin.z
		message_end();
		
		//create some sound
		emit_sound(id, CHAN_ITEM, "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM);
		
		//Ignite Others 
		if(get_pcvar_num(g_pAllowCatchFire)) 
		{       
			new iTempOriginOrigin[3];
			
			new iPlayers[32], iPlayerNum, iTempid;
			get_players(iPlayers, iPlayerNum, "a");
			
			new szVictimName[32], szIgniterName[32]; 
			
			for(new i = 0; i < iPlayerNum; ++i) 
			{                   
				iTempid = iPlayers[i];
				
				get_user_origin(iTempid, iTempOriginOrigin);
				
				if(get_distance(iIdOrigin, iTempOriginOrigin) < 100)
				{ 
					if(!CheckPlayerBit(g_iOnFireBit, iTempid)) 
					{ 
						get_user_name(iTempid, szVictimName, charsmax(szVictimName));
						get_user_name(id, szIgniterName, charsmax(szIgniterName)); 
						
						emit_sound(iTempid, CHAN_WEAPON, "scientist/scream07.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH); 
						client_print(0, print_chat, "* [AMX] OH! NO! %s has caught %s on fire!", szIgniterName, szVictimName);
						
						SetPlayerBit(g_iOnFireBit, iTempid);
						
						ignite_player(iTempid);
						ignite_effects(iTempid);
					}                
				} 
			}           
		} 
		
		//Call Again in 2 seconds       
		set_task(2.0, "ignite_player", id);       
	}    
} 

/* 21)	amx_flash
 *---------------
*/
public Cmd_Flash(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szArg1[35], szTargetName[35];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new szAdminName[35], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	
	new iTempid;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum;
		new CmdTeam: team;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && id != iTempid)
			{
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			Flash_Player(iTempid);
		}
		
		console_print(id, "%L", id, "AMX_SUPER_FLASH_TEAM_MSG", g_szTeamNames[team]);
		
		show_activity_key("AMX_SUPER_FLASH_TEAM_CASE1", "AMX_FLASH_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FLASH_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			Flash_Player(iTempid);
			
			new szTargetAuthid[35];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			console_print(id, "%L", id, "AMX_SUPER_FLASH_PLAYER_MSG", szTargetName);
			
			show_activity_key("AMX_SUPER_FLASH_PLAYER_CASE1", "AMX_SUPER_FLASH_PLAYER_CASE2", szAdminName, szTargetName);
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_FLASH_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
		}
	}
	
	return PLUGIN_HANDLED;
}

Flash_Player(id)
{
	message_begin(MSG_ONE, g_iMsgScreenFade, {0,0,0}, id);
	write_short(1<<15);
	write_short(1<<10);
	write_short(1<<12);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();

	if(get_pcvar_num(g_pFlashSound))
		emit_sound(id, CHAN_BODY, "weapons/flashbang-2.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH);
}

/* 22)	amx_uberslap
 *------------------
*/
public Cmd_UberSlap(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
		
	new szArg1[35];
	read_argv(1, szArg1, charsmax(szArg1));
	
	new szTargetName[35], szAdminName[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
			
	new szAdminAuthid[35];
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	new iTempid;
	
	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum;
		new CmdTeam: team;
		
		switch(szArg1[1])
		{
			case 'A', 'a':
			{
				get_players(iPlayers, iPlayerNum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!iPlayerNum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if((get_user_flags(iTempid) & ADMIN_IMMUNITY) && id != iTempid)
			{	
				get_user_name(iTempid, szTargetName, charsmax(szTargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", szTargetName);
				
				continue;
			}
			
			set_task(0.1, "Slap_Player", iTempid, _, _, "a", 100);
		}
		
		show_activity_key("AMX_SUPER_UBERSLAP_TEAM_CASE1", "AMX_SUPER_UBERSLAP_TEAM_CASE2", szAdminName, g_szTeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UBERSLAP_TEAM_LOG", szAdminName, szAdminAuthid, g_szTeamNames[team]);
	}
	
	else
	{
		iTempid = cmd_target(id, szArg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(iTempid)
		{
			get_user_name(iTempid, szTargetName, charsmax(szTargetName));
			
			new szTargetAuthid[35];
			get_user_authid(iTempid, szTargetAuthid, charsmax(szTargetAuthid));
					
			set_task(0.1, "Slap_Player", iTempid, _, _, "a", 100);
			
			show_activity_key("AMX_SUPER_UBERSLAP_PLAYER_CASE1", "AMX_SUPER_UBERSLAP_PLAYER_CASE2", szAdminName, szTargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_UBERSLAP_PLAYER_LOG", szAdminName, szAdminAuthid, szTargetName, szTargetAuthid);
			
			console_print(id, "%L", id, "AMX_SUPER_UBERSLAP_PLAYER_MSG", szTargetName);
		}
	}

	return PLUGIN_HANDLED;
}

public Slap_Player(id)
{
	if(get_user_health(id) > 1)
		user_slap(id, 1);
	
	else
		user_slap(id, 0);
}

/* 23)	amx_glow(2)
 *-----------------
*/
public Cmd_Glow(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED;
		
	new szArg0[20], szArg1[35], szColor[20], szGreen[3], szBlue[3], szAlpha[3];
	read_argv(0, szArg0, charsmax(szArg0)); 			
	read_argv(1, szArg1, charsmax(szArg1));		
	read_argv(2, szColor, charsmax(szColor));		
	read_argv(3, szGreen, charsmax(szGreen));
	read_argv(4, szBlue, charsmax(szBlue));
	read_argv(5, szAlpha, charsmax(szAlpha));
	
	new iRed, iGreen, iBlueNum, iAlpha;
	
	new bool: bOff;
	new bool: bGlow2;
	
	if(szArg0[8] == '2')
		bGlow2 = true;
		
	else 
		bGlow2 = false;
		
	if(!strlen(szGreen))
	{
		new bool: bIsValidColor = false;
		
		for(new i = 0; i < MAX_COLORS; i++)
		{
			if(equali(szColor, g_szColorNames[i]))
			{	
				iRed = g_iColorValues[i][0];
				iGreen = g_iColorValues[i][1];
				iBlueNum = g_iColorValues[i][2];
				iAlpha = 255;
				
				if(equali(szColor, "off"))
					bOff = true;
				
				else 
					bOff = false;
					
				bIsValidColor = true;
				
				break;
			}
		}
		
		if(!bIsValidColor)
		{ 
			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GLOW_INVALID_COLOR");
			
			return PLUGIN_HANDLED;
		}
	}
	
	else
	{
		iRed = str_to_num(szColor);
		iGreen = str_to_num(szGreen);
		iBlueNum = str_to_num(szBlue);
		iAlpha = str_to_num(szAlpha);
		
		clamp(iRed, 0, 255);
		clamp(iGreen, 0, 255);
		clamp(iBlueNum, 0, 255);
		clamp(iAlpha, 0, 255);
	}
	
	new iTempid;
	new szAdminName[34], szAdminAuthid[35];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));

	if(szArg1[0] == '@')
	{
		new iPlayers[32], iPlayerNum;
		
		if(equali(szArg1[1], "T"))
			copy(szArg1[1], charsmax(szArg1), "TERRORIST");
		
		if(equali(szArg1[1], "ALL"))
			get_players(iPlayers, iPlayerNum, "a");
		
		else
			get_players(iPlayers, iPlayerNum, "ae", szArg1[1]);
			
		for(new i = 0; i < iPlayerNum; i++)
		{
			iTempid = iPlayers[i];
			
			if(bGlow2)
			{
				g_iGlowColors[iTempid][0] = iRed;
				g_iGlowColors[iTempid][1] = iGreen;
				g_iGlowColors[iTempid][2] = iBlueNum;
				g_iGlowColors[iTempid][3] = iAlpha;
				
				g_iFlags[iTempid] |= HASGLOW;
				
			}
			
			else
			{
				arrayset(g_iGlowColors[iTempid], 0, 4);
				g_iFlags[iTempid] &= ~HASGLOW;
			}
			
			set_user_rendering(iTempid, kRenderFxGlowShell, iRed, iGreen, iBlueNum, kRenderTransAlpha, iAlpha);
		}
		
		if(bOff)
			show_activity_key("AMX_SUPER_GLOW_TEAM_OFF_CASE1", "AMX_SUPER_GLOW_TEAM_OFF_CASE2", szAdminName, szArg1[1]);
		
		else
			show_activity_key("AMX_SUPER_GLOW_TEAM_CASE1", "AMX_SUPER_GLOW_TEAM_CASE2", szAdminName, szArg1[1]);
		
		console_print(id, "%L", id, "AMX_SUPER_GLOW_TEAM_MSG", szArg1[1]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GLOW_TEAM_LOG", szAdminName, szAdminAuthid, szArg1[1]);
	}

	else
	{
		iTempid = cmd_target(id, szArg1, 2);
		
		if(!iTempid)
			return PLUGIN_HANDLED;
			
		if(bGlow2)
		{
			g_iGlowColors[iTempid][0] = iRed;
			g_iGlowColors[iTempid][1] = iGreen;
			g_iGlowColors[iTempid][2] = iBlueNum;
			g_iGlowColors[iTempid][3] = iAlpha;
			
			g_iFlags[iTempid] |= HASGLOW;
		}
		
		else
		{
			arrayset(g_iGlowColors[iTempid], 0, sizeof(g_iGlowColors[]));
			g_iFlags[iTempid] &= ~HASGLOW;
		}
		
		set_user_rendering(iTempid, kRenderFxGlowShell, iRed, iGreen, iBlueNum, kRenderTransAlpha, iAlpha);
		
		new szTargetName[35];
		get_user_name(iTempid, szTargetName, charsmax(szTargetName));
		
		if(bOff)
			show_activity_key("AMX_SUPER_GLOW_PLAYER_OFF_CASE1", "AMX_SUPER_GLOW_PLAYER_OFF_CASE2", szAdminName, szTargetName);
			
		else
			show_activity_key("AMX_SUPER_GLOW_PLAYER_CASE1", "AMX_SUPER_GLOW_PLAYER_CASE2", szAdminName, szTargetName);

		console_print(id, "%L", id, "AMX_SUPER_GLOW_TEAM_MSG", szTargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GLOW_TEAM_LOG", szAdminName, szAdminAuthid, szTargetName);
	}
	return PLUGIN_HANDLED;
}

/* 24)	amx_glowcolors
 *--------------------
*/
public Cmd_GlowColors(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
		return PLUGIN_HANDLED;
	
	console_print(id, "Colors:");
	
	for(new i = 0; i < MAX_COLORS; i++)
		console_print(id, "%i %s", i + 1, g_szColorNames[i]);
	
	console_print(id, "Example: ^"amx_glow superman yellow^"");
	
	return PLUGIN_HANDLED;
}
