/* * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Super - Menu
 * Developed by Ryan "YamiKaitou" LeBlanc
 * Maintained by SuperCentral.co Scripting Team
 * Last Update: Jan 17 2014
 * 
 * Minimum Requirements
 * AMX Mod X 1.8.0
 * AMX Super 5.0
 * 
 * Credits
 * AMX Mod X Dev Team (for their plmenu.amxx plugin)
 * bmann|420 (for creating the AMX Super plugin)
 * |PJ|Shorty (for assisting me in finding out the get_concmd function)
 * If I forgot you, let me know what you did and I will add you
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Mod X script.
 *
 *   AMX Super - Menu (amx_super-menu.sma)
 *   Copyright (C) 2008-2010 Ryan "YamiKaitou" LeBlanc
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
 
#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "AMX_Super Menu"
#define AUTHOR  "SuperCentral.co"
#define VERSION "5.0.2"

enum 
{
	ALLTALK = 1,
	LOCK,
	UNLOCK,
	EXTEND,
	GRAVITY,
	FIRE,
	FLASH,
	DISARM,
	ROCKET,
	UBERSLAP,
	REVIVE,
	QUIT,
	DRUG,
	TEAMSWAP,
	HEAL,
	ARMOR,
	STACK,
	BURY,
	UNBURY,
	SLAY,
	GOD,
	NOCLIP,
	SPEED,
	UNAMMO,
	SWAP,
	SETMONEY,
	BADAIM,
	GAG,
	UNGAG,
	MAXVALUE
}

new const g_szDisabledCmdsFilename[] = "disabled_cmds.ini";

new Trie:g_tDisabledCmds;

new g_hMainMenu, g_hAllTalkMenu, g_hExtendMenu, g_hGravityMenu;

new g_pMenuEnabled;

new g_iMenuPosition[33], g_iMenuPlayers[33][35], g_iMenuPlayersNum[33], g_iMenuProperties[33], g_iMenuProperties2[33], g_iMenu[33];
new g_szMenuPlayerName[33][32];

new g_szMenuName[64];
new g_iAllKeys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9;
new g_hCallback;
new Array:g_aValueArray[MAXVALUE];
new g_iAccessLevel[MAXVALUE];

new g_szMenuCommands[][128] = 
{
	"status",
	"amx_alltalk %s",
	"amx_lock %s",
	"amx_unlock %s",
	"amx_extend %s",
	"amx_gravity %s",
	"amx_fire ^"%s^"",
	"amx_flash ^"%s^"",
	"amx_disarm ^"%s^"",
	"amx_rocket ^"%s^"",
	"amx_uberslap ^"%s^"",
	"amx_revive ^"%s^"",
	"amx_quit ^"%s^"",
	"amx_drug ^"%s^" 1",
	"amx_teamswap",
	"amx_heal ^"%s^" %d",
	"amx_armor ^"%s^" %d",
	"amx_stack ^"%s^" %d",
	"amx_bury ^"%s^"",
	"amx_unbury ^"%s^"",
	"amx_slay2 ^"%s^" %d",
	"amx_godmode ^"%s^" %d",
	"amx_noclip ^"%s^" %d",
	"amx_speed ^"%s^" %d",
	"amx_unammo ^"%s^" %d",
	"amx_swap ^"%s^" ^"%s^"",
	"amx_money ^"%s^" %d",
	"amx_badaim ^"%s^" %d 0",
	"amx_gag ^"%s^" %s %d",
	"amx_ungag ^"%s^""
};

new g_szCommands[][64] = 
{
	"nothing",
	"amx_alltalk",
	"amx_lock",
	"amx_unlock",
	"amx_extend",
	"amx_gravity",
	"amx_fire",
	"amx_flash",
	"amx_disarm",
	"amx_rocket",
	"amx_uberslap",
	"amx_revive",
	"amx_quit",
	"amx_drug",
	"amx_teamswap",
	"amx_heal",
	"amx_armor",
	"amx_stack",
	"amx_bury",
	"amx_unbury",
	"amx_slay2",
	"amx_godmode",
	"amx_noclip",
	"amx_speed",
	"amx_unammo",
	"amx_swap",
	"amx_money",
	"amx_badaim",
	"amx_gag",
	"amx_ungag"
};

new bool:g_bCommandManagerEnabled;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("amx_super_menu",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY);
	g_pMenuEnabled = register_cvar("amx_supermenu_enabled", "1");
	register_dictionary("amx_super_menu.txt");
	register_dictionary("common.txt");
	
	// Register New Menus
	format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_MENU0");
	g_hMainMenu = menu_create(g_szMenuName, "MainMenuHandler");
	format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_MENU1");
	g_hAllTalkMenu = menu_create(g_szMenuName, "AllTalkMenuHandler");
	format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_MENU4");
	g_hExtendMenu = menu_create(g_szMenuName, "ExtendMenuHandler");
	format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_MENU5");
	g_hGravityMenu = menu_create(g_szMenuName, "GravityMenuHandler");
	
	g_tDisabledCmds = TrieCreate();
	
	g_bCommandManagerEnabled = is_plugin_loaded("AMX Super Cmd Manager") == -1 ? false : true;
	
	// Register g_hCallbacks
	g_hCallback = menu_makecallback("MenuCallback");    
	
	// Register Old Menus
	register_menucmd(register_menuid("Lock Menu"), g_iAllKeys, "LockMenuHandler");
	register_menucmd(register_menuid("Player1 Menu"), g_iAllKeys, "Player1MenuHandler");
	register_menucmd(register_menuid("Player2 Menu"), g_iAllKeys, "Player2MenuHandler");
	register_menucmd(register_menuid("Gag Menu"), g_iAllKeys, "GagMenuHandler");
	
	register_clcmd("say", "HandleSay");
	register_clcmd("say_team", "HandleSay");
	register_concmd("supermenu", "HandleCmd", ADMIN_MENU, " - Bring up the menu for AMX_Super");
	register_concmd("amx_supermenu", "HandleCmd", ADMIN_MENU, " - Bring up the menu for AMX_Super");
	register_concmd("supermenu_edit", "HandleCmd", ADMIN_MENU, " - Allows you to edit the values the menu displays");
	register_concmd("amx_supermenu_edit", "HandleCmd", ADMIN_MENU, " - Allows you to edit the values the menu displays");
	register_concmd("amx_reloadcmds", "CmdReloadCmds", ADMIN_CVAR, "Reloads all amx super commands. (see disabled_cmds.ini)");
	
	arrayset(g_iAccessLevel, -2, MAXVALUE);
	
	AddMenuItem("AMX_Super Menu", "amx_supermenu", ADMIN_MENU, PLUGIN);
	
	CmdReloadCmds(0, 0, 0); 
}

public CmdReloadCmds(id, iLevel, iCid)
{
	if(!g_bCommandManagerEnabled || (id && !cmd_access(id, iLevel, iCid, 1)))
		return PLUGIN_HANDLED;
	
	new szDisabledCmdFile[64], iFile;
	get_configsdir(szDisabledCmdFile, charsmax(szDisabledCmdFile));
	format(szDisabledCmdFile, charsmax(szDisabledCmdFile), "%s/%s", szDisabledCmdFile, g_szDisabledCmdsFilename);
		
	// read commands into Trie if file exists.
	if(file_exists(szDisabledCmdFile))
	{
		// Clear our previous commands before reading new ones.
		TrieClear(g_tDisabledCmds);
		
		if((iFile = fopen(szDisabledCmdFile, "rt")))
		{
			new szCurrentCmd[32];
		
			while(!feof(iFile))
			{
				fgets(iFile, szCurrentCmd, charsmax(szCurrentCmd));
				trim(szCurrentCmd);
				
				if(!szCurrentCmd[0] || szCurrentCmd[0] == ';' || szCurrentCmd[0] == '/' && szCurrentCmd[1] == '/')
					continue;
					
				TrieSetCell(g_tDisabledCmds, szCurrentCmd, 1);
			}
			
			fclose(iFile);
		}
	
		else            // TODO: ML
			log_amx("[AMXX] Failed to open '%s' !", g_szDisabledCmdsFilename);
	}

	return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
	new iIndex = 0, szCommand[64], iFlags, szInfo[128], iFlag = 52428799, k;
	new iMax = get_concmdsnum(iFlag);
	
	while(iIndex <= iMax)
	{
		get_concmd(iIndex++, szCommand, charsmax(szCommand), iFlags, szInfo, charsmax(szInfo), iFlag);
		
		k = 1;
		while (k < MAXVALUE && !equal(szCommand, g_szCommands[k])) k++;
		
		if (k != MAXVALUE) g_iAccessLevel[k] = iFlags;
	}
	
	BuildArrays();
	BuildMenu();
}

public HandleSay(id)
{
	new szArg[32];
	read_argv(1, szArg, charsmax(szArg));
	
	if (equal(szArg, "/supermenu"))
	{
		menu_display(id, g_hMainMenu, 0);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public HandleCmd(id, iLevel, iCid)
{
	new szCommand[64];
	read_argv(0, szCommand, charsmax(szCommand));
		
	if (equal(szCommand, "supermenu") || equal(szCommand, "amx_supermenu"))
		menu_display(id, g_hMainMenu, 0);
	else if (equal(szCommand, "supermenu_edit") || equal(szCommand, "amx_supermenu_edit"))
	{
		if (read_argc() < 2)
		{
			client_print(id, print_console, "%L", id, "AMXSUPER_NOPARM");
			client_print(id, print_console, "%L %s <menu to edit> <value1> [value2] [value3] [value4] ...", id, "USAGE", szCommand);
			return PLUGIN_HANDLED;
		}
		
		new szType[10], iValue, Array:aTemp = ArrayCreate();
		read_argv(1, szType, charsmax(szType));
		
		if (equal(szType, "extend"))
			iValue = EXTEND;
		else if (equal(szType, "gravity"))
			iValue = GRAVITY;
		else if (equal(szType, "heal"))
			iValue = HEAL;
		else if (equal(szType, "armor"))
			iValue = ARMOR;
		else if (equal(szType, "money"))
			iValue = SETMONEY;
		else if (equal(szType, "badaim"))
			iValue = BADAIM;
		else if (equal(szType, "gag"))
			iValue = GAG;
		
		if (!(get_user_flags(id) & g_iAccessLevel[iValue]))
		{
			client_print(id, print_console, "%L", id, "NO_ACC_COM");
			return PLUGIN_HANDLED;
		}
		new szMessage[256], iMax = ArraySize(Array:g_aValueArray[iValue]), k = (iValue == BADAIM) ? 2 : 0;
		if (read_argc() < 3)
		{
			client_print(id, print_console, "%L", id, "AMXSUPER_NOPARM");
			client_print(id, print_console, "%L %s %s <value1> [value2] [value3] [value4] ...", id, "USAGE", szCommand, szType);
			format(szMessage, charsmax(szMessage), "%d", ArrayGetCell(Array:g_aValueArray[iValue], k++));
			while (k < iMax)
				format(szMessage, charsmax(szMessage), "%s, %d", szMessage, ArrayGetCell(Array:g_aValueArray[iValue], k++));
			client_print(id, print_console, "%L: %s", id, "AMXSUPER_CURRENT", szType, szMessage);
			return PLUGIN_HANDLED;
		}
		
		if (iValue == EXTEND)
		{
			menu_destroy(g_hExtendMenu);
			
			// Recreating it and building it
			format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_MENU4");
			g_hExtendMenu = menu_create(g_szMenuName, "extendMenu");
			
			new szArg[4], k = 2;
			while(k)
			{
				read_argv(k, szArg, charsmax(szArg));
				if(equal(szArg, "")) break;
				ArrayPushCell(aTemp, str_to_num(szArg));
				k++;
				format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_EXTEND", szArg);
				menu_additem(g_hExtendMenu, g_szMenuName, szArg);
			}
		}
		else if (iValue == GRAVITY)
		{
			menu_destroy(g_hGravityMenu);
			
			// Recreating it and building it
			format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_MENU5");
			g_hGravityMenu = menu_create(g_szMenuName, "GravityMenuHandler");
			
			new szArg[6], k = 2;
			while (k)
			{
				read_argv(k, szArg, charsmax(szArg));
				if (equal(szArg, "")) break;
				ArrayPushCell(aTemp, str_to_num(szArg));
				k++;
				menu_additem(g_hGravityMenu, szArg, szArg);
			}
		}
		else
		{
			if (iValue == BADAIM)
			{
				ArrayPushCell(aTemp, 0);
				ArrayPushCell(aTemp, 1);
			}
			new szArg[6], k = 2;
			while(k)
			{
				read_argv(k, szArg, charsmax(szArg));
				if (equal(szArg, "")) break;
				ArrayPushCell(aTemp, str_to_num(szArg));
				k++;
			}
		}
		
		iMax = ArraySize(aTemp), k = 0;
		format(szMessage, charsmax(szMessage), "%d", ArrayGetCell(aTemp, k++));
		while(k < iMax)
			format(szMessage, charsmax(szMessage), "%s, %d", szMessage, ArrayGetCell(aTemp, k++));
		client_print(id, print_console, "%L: %s", id, "AMXSUPER_CURRENT", szType, szMessage);
		g_aValueArray[iValue] = aTemp;
	}   
	return PLUGIN_HANDLED;
}

BuildArrays()
{
	g_aValueArray[EXTEND] = ArrayCreate();
	for (new k = 5; k < 16; k+=5)
		ArrayPushCell(Array:g_aValueArray[EXTEND], k);
	for (new k = 30; k < 61; k+=15)
		ArrayPushCell(Array:g_aValueArray[EXTEND], k);
	
	g_aValueArray[GRAVITY] = ArrayCreate();
	for (new k = 0; k < 7; k++)
		ArrayPushCell(Array:g_aValueArray[GRAVITY], k * 200);
	
	g_aValueArray[HEAL] = ArrayCreate();
	g_aValueArray[ARMOR] = ArrayCreate();
	ArrayPushCell(Array:g_aValueArray[HEAL], 10);
	ArrayPushCell(Array:g_aValueArray[ARMOR], 10);
	for (new k = 1; k < 5; k++)
	{
		ArrayPushCell(Array:g_aValueArray[HEAL], k * 25);
		ArrayPushCell(Array:g_aValueArray[ARMOR], k * 25);
	}
	ArrayPushCell(Array:g_aValueArray[HEAL], 200);
	ArrayPushCell(Array:g_aValueArray[ARMOR], 200);
	
	g_aValueArray[SETMONEY] = ArrayCreate();
	for (new k = 500; k < 16001; k*=2)
		ArrayPushCell(Array:g_aValueArray[SETMONEY], k);
	
	g_aValueArray[BADAIM] = ArrayCreate();
	ArrayPushCell(Array:g_aValueArray[BADAIM], 0);
	ArrayPushCell(Array:g_aValueArray[BADAIM], 1);
	for (new k = 5; k < 16; k+=5)
		ArrayPushCell(Array:g_aValueArray[BADAIM], k);
	for (new k = 30; k < 61; k+=15)
		ArrayPushCell(Array:g_aValueArray[BADAIM], k);
	
	g_aValueArray[GAG] = ArrayCreate();
	ArrayPushCell(Array:g_aValueArray[GAG], 30);
	ArrayPushCell(Array:g_aValueArray[GAG], 60);
	ArrayPushCell(Array:g_aValueArray[GAG], 300);
	for (new k = 600; k < 1801; k+=600)
		ArrayPushCell(Array:g_aValueArray[GAG], k);
}

BuildMenu()
{
	new szValue[20];
	
	// Build Main Menu
	for (new iNum = 1; iNum < MAXVALUE; iNum++)
	{
		if (iNum == UNLOCK || iNum == UNBURY || iNum == UNGAG)
			continue;
		
		new szKey[17], szNum[3];
		format(szKey, charsmax(szKey), "AMXSUPER_MENU%d", iNum);
		format(szNum, charsmax(szNum), "%d", iNum);
		format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, szKey);
		if (g_iAccessLevel[iNum] != -2)
			menu_additem(g_hMainMenu, g_szMenuName, szNum, _, g_hCallback);
	}
	
	// Build Alltalk Menu
	format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_ENABLE");
	menu_additem(g_hAllTalkMenu, g_szMenuName, "1");
	format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_DISABLE");
	menu_additem(g_hAllTalkMenu, g_szMenuName, "0");
	
	// Build Extend Menu
	for (new k = 0; k < 6; k++)
	{
		format(szValue, charsmax(szValue), "%d", ArrayGetCell(Array:g_aValueArray[EXTEND], k));
		format(g_szMenuName, charsmax(g_szMenuName), "%L", LANG_PLAYER, "AMXSUPER_EXTEND", szValue);
		menu_additem(g_hExtendMenu, g_szMenuName, szValue);
	}
	
	// Build Gravity Menu
	for (new k = 0; k < 6; k++)
	{
		format(szValue, charsmax(szValue), "%d", ArrayGetCell(Array:g_aValueArray[GRAVITY], k));
		menu_additem(g_hGravityMenu, szValue, szValue);
	}
}

GetMenuPlayers(&iNum, iMenu)
{
	new iTemp[32], iPlayers[35], k;
	
	switch(iMenu)
	{
		case FIRE, FLASH, DISARM, ROCKET, UBERSLAP, DRUG, HEAL, ARMOR, STACK, BURY, UNBURY, SLAY, GOD, NOCLIP, SPEED, UNAMMO, BADAIM:
			get_players(iTemp, iNum, "a");
		
		case REVIVE:
			get_players(iTemp, iNum, "b");
		
		case GAG:
			get_players(iTemp, iNum, "c");
			
		default:
			get_players(iTemp, iNum);
	}
	
	for (k = 0; k < iNum; k++) iPlayers[k] = iTemp[k];
	/*
	if(iMenu == SWAP)
	{
		iPlayers[k] = 34;
		iPlayers[k+1] = 35;
		iNum += 2;
	}
	
	else
	*/
	if(iMenu != SWAP && iMenu != GAG)
	{
		iPlayers[k] = 33;
		iPlayers[k+1] = 34;
		iPlayers[k+2] = 35;
		iNum += 3;
	}
	
	return iPlayers;
}

public MenuCallback(id, hMenu, iItem)
{
	if (iItem < 0)
		return ITEM_DISABLED;
	
	new szCommand[3], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szCommand, 2, _, _, hCallback);
	
	new iNum = str_to_num(szCommand);
	
	if(TrieKeyExists(g_tDisabledCmds, g_szCommands[iNum]))
		return ITEM_DISABLED;
		
	if (get_user_flags(id) & g_iAccessLevel[iNum])
		return ITEM_ENABLED;
		
	return ITEM_DISABLED;
}

public MainMenuHandler(id, hMenu, iItem)
{
	if (iItem < 0)
		return PLUGIN_CONTINUE;
	
	new szCommand[3];
	new iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szCommand, 2, _, _, hCallback);
	
	new iNum = str_to_num(szCommand);
		
	g_iMenuProperties[id] = 0;
	g_iMenuPosition[id] = 0;
	
	switch(iNum)
	{
		case ALLTALK:
			menu_display(id, g_hAllTalkMenu, 0);
		case LOCK, UNLOCK:
			DisplayLockMenu(id);
		case EXTEND:
			menu_display(id, g_hExtendMenu, 0);
		case GRAVITY:
			menu_display(id, g_hGravityMenu, 0);
		case TEAMSWAP:
		{
			client_cmd(id, g_szCommands[TEAMSWAP]);
			return PLUGIN_HANDLED;
		}
		case GAG:
			DisplayGagMenu(id, 0);
		case FIRE, FLASH, DISARM, ROCKET, UBERSLAP, REVIVE, QUIT, DRUG, SWAP:
			DisplayPlayer1Menu(id, 0, iNum);
		case HEAL, ARMOR, STACK, BURY, UNBURY, SLAY, GOD, NOCLIP, SPEED, UNAMMO, SETMONEY, BADAIM:
			DisplayPlayer2Menu(id, 0, iNum);
	}
	
	return PLUGIN_CONTINUE;
}

public AllTalkMenuHandler(id, hMenu, iItem)
{       
	if (iItem == MENU_EXIT)
	{   
		if(get_pcvar_num(g_pMenuEnabled))
			menu_display(id, g_hMainMenu, 0);
			
		return PLUGIN_CONTINUE;
	}
	if (iItem < 0)
		return PLUGIN_CONTINUE;
	
	new szCommand[3], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szCommand, 2,_,_, hCallback);
	
	client_cmd(id, g_szMenuCommands[ALLTALK], szCommand);
	
	return PLUGIN_HANDLED;  
}

public LockMenuHandler(id, iKey)
{
	new szTeam[6];
	switch(iKey)
	{
		case 0:
			format(szTeam, charsmax(szTeam), "CT");
		case 1:
			format(szTeam, charsmax(szTeam), "T");
		case 2:
			format(szTeam, charsmax(szTeam), "Auto");
		case 3:
			format(szTeam, charsmax(szTeam), "Spec");
		case 4:
		{
			if (g_iMenuProperties[id] == LOCK)
				g_iMenuProperties[id] = UNLOCK;
			else
				g_iMenuProperties[id] = LOCK;
				
			DisplayLockMenu(id);
			return PLUGIN_HANDLED;
		}
		case 9:
		{
			if (get_pcvar_num(g_pMenuEnabled))
				menu_display(id, g_hMainMenu, 0);

			return PLUGIN_HANDLED;
		}
		default: return PLUGIN_HANDLED;
	}
	
	client_cmd(id, g_szMenuCommands[g_iMenuProperties[id]], szTeam);
	
	DisplayLockMenu(id);
	
	return PLUGIN_HANDLED;
}

DisplayLockMenu(id)
{
	new szMenuBody[1000], szLine[100];
	
	format(szMenuBody, charsmax(szMenuBody), "\y");
	if (g_iMenuProperties[id] == LOCK)
		format(szLine, charsmax(szLine), "%L ^n", id, "AMXSUPER_LOCK");
	else
	{
		format(szLine, charsmax(szLine), "%L ^n", id, "AMXSUPER_UNLOCK");
		g_iMenuProperties[id] = UNLOCK;
	}
	
	add(szMenuBody, charsmax(szMenuBody), szLine);
	format(szLine, charsmax(szLine), "^n\w^n");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	format(szLine, charsmax(szLine), "1. %L ^n", id, "AMXSUPER_TEAMCT");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	format(szLine, charsmax(szLine), "2. %L ^n", id, "AMXSUPER_TEAMT");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	format(szLine, charsmax(szLine), "3. %L ^n", id, "AMXSUPER_TEAMAUTO");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	format(szLine, charsmax(szLine), "4. %L ^n", id, "AMXSUPER_TEAMSPEC");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	if (g_iMenuProperties[id] == LOCK)
		format(szLine, charsmax(szLine), "^n5. %L ^n", id, "AMXSUPER_LOCK");
	else
		format(szLine, charsmax(szLine), "^n5. %L ^n", id, "AMXSUPER_UNLOCK");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	format(szLine, charsmax(szLine), "^n^n0. %L", id, "EXIT");
	add(szMenuBody, charsmax(szMenuBody), szLine);
	new iKeys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5;
		
	show_menu(id, iKeys, szMenuBody, -1, "Lock Menu");
}

public ExtendMenuHandler(id, hMenu, iItem)
{
	if (iItem == MENU_EXIT && get_pcvar_num(g_pMenuEnabled))
	{
		menu_display(id, g_hMainMenu, 0);
		return PLUGIN_CONTINUE;
	}
	if (iItem < 0)
		return PLUGIN_CONTINUE;
	
	new szCommand[4], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szCommand, 3,_,_, hCallback);
	
	client_cmd(id, g_szMenuCommands[EXTEND], szCommand);
	
	return PLUGIN_HANDLED;
}

public GravityMenuHandler(id, hMenu, iItem)
{
	if (iItem == MENU_EXIT && get_pcvar_num(g_pMenuEnabled))
	{
		menu_display(id, g_hMainMenu, 0);
		return PLUGIN_CONTINUE;
	}
	if (iItem < 0)
		return PLUGIN_CONTINUE;
	
	new szCommand[5], iAccess, hCallback;
	menu_item_getinfo(hMenu, iItem, iAccess, szCommand, 4,_,_, hCallback);
	
	client_cmd(id, g_szMenuCommands[GRAVITY], szCommand);
	
	return PLUGIN_HANDLED;
}

public Player1MenuHandler(id, iKey)
{
	switch (iKey)
	{
		case 8: DisplayPlayer1Menu(id, ++g_iMenuPosition[id], g_iMenu[id]);
		case 9: DisplayPlayer1Menu(id, --g_iMenuPosition[id], g_iMenu[id]);
		default:
		{
			new iPlayer = g_iMenuPlayers[id][g_iMenuPosition[id] * 8 + iKey];
			new szName[32];
			
			if (g_iMenu[id] != SWAP)
			{
				switch (iPlayer)
				{
					case 33: format(szName, charsmax(szName), "@ALL");
					case 34: format(szName, charsmax(szName), "@T");
					case 35: format(szName, charsmax(szName), "@CT");
					default: get_user_name(iPlayer, szName, charsmax(szName));
				}
				client_cmd(id, g_szMenuCommands[g_iMenu[id]], szName);
			}
			else
			{
				get_user_name(iPlayer, szName, charsmax(szName));
				
				if (equal(g_szMenuPlayerName[id], ""))
				{
					format(g_szMenuPlayerName[id], 31, "%s", szName);
					g_iMenuPosition[id] = 0;
					DisplayPlayer1Menu(id, g_iMenuPosition[id], g_iMenu[id]);
				}
				else
				{
					client_cmd(id, g_szMenuCommands[SWAP], g_szMenuPlayerName[id], szName);
					format(g_szMenuPlayerName[id], 31, "");
				}
			}
		}
	}
	
	DisplayPlayer1Menu(id, g_iMenuPosition[id], g_iMenu[id]); 
	
	return PLUGIN_HANDLED;
}

DisplayPlayer1Menu(id, iPos, iMenu)
{
	if (iPos < 0)
	{
		if (get_pcvar_num(g_pMenuEnabled))
			menu_display(id, g_hMainMenu, 0);
		return;
	}
	
	g_iMenu[id] = iMenu;
	g_iMenuPlayers[id] = GetMenuPlayers(g_iMenuPlayersNum[id], iMenu);

	new szMenuBody[1024];
	new b = 0;
	new i;
	new szName[32];
	new iStart = iPos * 8;
	
	if (iStart >= g_iMenuPlayersNum[id])
		iStart = iPos = g_iMenuPosition[id] = 0;
	
	new szKey[17];
	format(szKey, charsmax(szKey), "AMXSUPER_MENU%d", iMenu);
	new iLen = format(szMenuBody, 1023, "\y%L\R%d/%d^n\w^n", id, szKey, iPos + 1, (g_iMenuPlayersNum[id] / 8 + ((g_iMenuPlayersNum[id] % 8) ? 1 : 0)));
	new iEnd = iStart + 8;
	new iKeys = MENU_KEY_0;

	if (iEnd > g_iMenuPlayersNum[id])
		iEnd = g_iMenuPlayersNum[id];

	for (new a = iStart; a < iEnd; ++a)
	{
		i = g_iMenuPlayers[id][a];
		
		if (g_iMenu[id] != SWAP)
			switch (i)
			{
				case 33: format(szName, charsmax(szName), "%L", id, "AMXSUPER_ALL");
				case 34: format(szName, charsmax(szName), "%L", id, "AMXSUPER_TEAMT");
				case 35: format(szName, charsmax(szName), "%L", id, "AMXSUPER_TEAMCT");
				default: get_user_name(i, szName, 31);
			}
		else
			get_user_name(i, szName, 31);
		
		if (i < 33 && i != id && access(i, ADMIN_IMMUNITY))
		{
			++b;
			iLen += format(szMenuBody[iLen], 1023-iLen, "\d\r%d. \w%s^n\w", b, szName);
		} else {
			iKeys |= (1<<b);
				
			if (i < 33 && is_user_admin(i))
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r%d. \w%s \r*^n\w", ++b, szName);
			else
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r%d. \w%s^n", ++b, szName);
		}
	}

	if (iEnd != g_iMenuPlayersNum[id])
	{
		format(szMenuBody[iLen], 1023-iLen, "^n\r9. \w%L...^n\r0. \w%L", id, "MORE", id, iPos ? "BACK" : "EXIT");
		iKeys |= MENU_KEY_9;
	}
	else
		format(szMenuBody[iLen], 1023-iLen, "^n\r0. \w%L", id, iPos ? "BACK" : "EXIT");

	show_menu(id, iKeys, szMenuBody, -1, "Player1 Menu");
}

public Player2MenuHandler(id, iKey)
{
	switch (iKey)
	{
		case 7:
		{
			switch (g_iMenu[id])
			{
				case HEAL, ARMOR, SETMONEY: if (++g_iMenuProperties[id] > 5) g_iMenuProperties[id] = 0;
				case STACK, GOD, NOCLIP: if (++g_iMenuProperties[id] > 2) g_iMenuProperties[id] = 0;
				case SLAY: if (++g_iMenuProperties[id] > 3) g_iMenuProperties[id] = 1;
				case SPEED, UNAMMO, BURY, UNBURY: if (++g_iMenuProperties[id] > 1) g_iMenuProperties[id] = 0;
				case BADAIM: if (++g_iMenuProperties[id] > 7) g_iMenuProperties[id] = 0;
			}
			DisplayPlayer2Menu(id, g_iMenuPosition[id], g_iMenu[id]);
		}
		case 8: DisplayPlayer2Menu(id, ++g_iMenuPosition[id], g_iMenu[id]);
		case 9: DisplayPlayer2Menu(id, --g_iMenuPosition[id], g_iMenu[id]);
		default:
		{
			new iPlayer = g_iMenuPlayers[id][g_iMenuPosition[id] * 7 + iKey];
			new szName[32];
			
			switch (iPlayer)
			{
				case 33: format(szName, charsmax(szName), "@ALL");
				case 34: format(szName, charsmax(szName), "@T");
				case 35: format(szName, charsmax(szName), "@CT");
				default: get_user_name(iPlayer, szName, charsmax(szName));
			}
			
			switch (g_iMenu[id])
			{
				case HEAL, ARMOR, BADAIM, SETMONEY: client_cmd(id, g_szMenuCommands[g_iMenu[id]], szName, ArrayGetCell(Array:g_aValueArray[g_iMenu[id]], g_iMenuProperties[id]));
				case STACK, SLAY, GOD, NOCLIP, SPEED, UNAMMO: client_cmd(id, g_szMenuCommands[g_iMenu[id]], szName, g_iMenuProperties[id]);
				case BURY, UNBURY: client_cmd(id, g_szMenuCommands[g_iMenuProperties[id] ? UNBURY : BURY], szName);
			}
		}
	}
	
	DisplayPlayer2Menu(id, g_iMenuPosition[id], g_iMenu[id]);
	
	return PLUGIN_HANDLED;
}

DisplayPlayer2Menu(id, iPos, iMenu)
{
	if (iPos < 0)
	{
		if (get_pcvar_num(g_pMenuEnabled))
			menu_display(id, g_hMainMenu, 0);
		return;
	}
	
	g_iMenu[id] = iMenu;
	g_iMenuPlayers[id] = GetMenuPlayers(g_iMenuPlayersNum[id], iMenu);

	new szMenuBody[1024];
	new b = 0;
	new i;
	new szName[32];
	new iStart = iPos * 7;
	
	if (iStart >= g_iMenuPlayersNum[id])
		iStart = iPos = g_iMenuPosition[id] = 0;
	
	new szKey[20];
	if (iMenu == BURY || iMenu == UNBURY)
		format(szKey, charsmax(szKey), "AMXSUPER_%s", (g_iMenuProperties[id]) ? "UNBURY" : "BURY");
	else
		format(szKey, charsmax(szKey), "AMXSUPER_MENU%d", iMenu);
	new iLen = format(szMenuBody, 1023, "\y%L\R%d/%d^n\w^n", id, szKey, iPos + 1, (g_iMenuPlayersNum[id] / 7 + ((g_iMenuPlayersNum[id] % 7) ? 1 : 0)));
	new iEnd = iStart + 7;
	new iKeys = MENU_KEY_0;

	if (iEnd > g_iMenuPlayersNum[id])
		iEnd = g_iMenuPlayersNum[id];

	for (new a = iStart; a < iEnd; ++a)
	{
		i = g_iMenuPlayers[id][a];
		
		switch (i)
		{
			case 33: format(szName, charsmax(szName), "%L", id, "AMXSUPER_ALL");
			case 34: format(szName, charsmax(szName), "%L", id, "AMXSUPER_TEAMT");
			case 35: format(szName, charsmax(szName), "%L", id, "AMXSUPER_TEAMCT");
			default: get_user_name(i, szName, 31);
		}
		
		if (i < 33 && i != id && access(i, ADMIN_IMMUNITY))
		{
			++b;
			iLen += format(szMenuBody[iLen], 1023-iLen, "\d\r%d. \w%s^n\w", b, szName);
		} else {
			iKeys |= (1<<b);
				
			if (i < 33 && is_user_admin(i))
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r%d. \w%s \r*^n\w", ++b, szName);
			else
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r%d. \w%s^n", ++b, szName);
		}
	}
	
	new szOption[20];
	if (iMenu == HEAL || iMenu == ARMOR || iMenu == BADAIM || iMenu == SETMONEY)
		format(szOption, charsmax(szOption), "%d", ArrayGetCell(Array:g_aValueArray[iMenu], g_iMenuProperties[id]));
		
	switch (iMenu)
	{
		case HEAL: iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, "AMXSUPER_HEAL", szOption);
		case ARMOR: iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, "AMXSUPER_ARMOR", szOption);
		case STACK: iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, "AMXSUPER_STACK", g_iMenuProperties[id]);
		case BURY, UNBURY: iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, (g_iMenuProperties[id]) ? "AMXSUPER_BURY" : "AMXSUPER_UNBURY");
		case SLAY:
		{
			if(!g_iMenuProperties[id])
				g_iMenuProperties[id] = 1;
				
			formatex(szKey, charsmax(szKey), "AMXSUPER_SLAY%d", g_iMenuProperties[id]);
			iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, szKey);
		}
		case GOD, NOCLIP, SPEED, UNAMMO:
		{
			format(szKey, charsmax(szKey), "AMXSUPER_GOD%d", g_iMenuProperties[id]);
			iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, szKey);
		}
		case BADAIM:
		{
			format(szKey, charsmax(szKey), "AMXSUPER_%s", (g_iMenuProperties[id] < 2) ? (g_iMenuProperties[id]) ? "GOD0" : "GOD1" : "MINS");
			if (g_iMenuProperties[id] < 2)
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, szKey);
			else
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, szKey, szOption);
		}
		case SETMONEY: iLen += format(szMenuBody[iLen], 1023-iLen, "\r8. \w%L", id, "AMXSUPER_SET", szOption);
	}
	iKeys |= MENU_KEY_8;
		
	if (iEnd != g_iMenuPlayersNum[id])
	{
		format(szMenuBody[iLen], 1023-iLen, "^n\r9. \w%L...^n\r0. \w%L", id, "MORE", id, iPos ? "BACK" : "EXIT");
		iKeys |= MENU_KEY_9;
	}
	else
		format(szMenuBody[iLen], 1023-iLen, "^n\r0. \w%L", id, iPos ? "BACK" : "EXIT");
	
	show_menu(id, iKeys, szMenuBody, -1, "Player2 Menu");
}

public GagMenuHandler(id, iKey)
{
	switch (iKey)
	{
		case 6:
		{
			if (++g_iMenuProperties[id] > 5) g_iMenuProperties[id] = 0;
			DisplayGagMenu(id, g_iMenuPosition[id]);
		}
		case 7:
		{
			if (++g_iMenuProperties2[id] > 7) g_iMenuProperties2[id] = 0;
			DisplayGagMenu(id, g_iMenuPosition[id]);
		}
		case 8: DisplayGagMenu(id, ++g_iMenuPosition[id]);
		case 9: DisplayGagMenu(id, --g_iMenuPosition[id]);
		default:
		{
			new iPlayer = g_iMenuPlayers[id][g_iMenuPosition[id] * 6 + iKey];
			new szName[32];
			
			// Drekes: Removed @TEAM values.
			get_user_name(iPlayer, szName, charsmax(szName));
			/*
			switch (iPlayer)
			{
				case 33: format(szName, charsmax(szName), "@ALL");
				case 34: format(szName, charsmax(szName), "@T");
				case 35: format(szName, charsmax(szName), "@CT");
				default: get_user_name(iPlayer, szName, charsmax(szName));
			}
			*/
			
			if (g_iMenuProperties2[id] == 7)
				client_cmd(id, g_szMenuCommands[UNGAG], szName);
			else
			{
				new szFlags[4];
				
				switch (g_iMenuProperties2[id])
				{
					case 0: format(szFlags, charsmax(szFlags), "a");
					case 1: format(szFlags, charsmax(szFlags), "b");
					case 2: format(szFlags, charsmax(szFlags), "c");
					case 3: format(szFlags, charsmax(szFlags), "ab");
					case 4: format(szFlags, charsmax(szFlags), "ac");
					case 5: format(szFlags, charsmax(szFlags), "bc");
					case 6: format(szFlags, charsmax(szFlags), "abc");
				}
				
				client_cmd(id, g_szMenuCommands[GAG], szName, szFlags, ArrayGetCell(Array:g_aValueArray[g_iMenu[id]], g_iMenuProperties[id]));
			}
		}
	}
	
	DisplayGagMenu(id, g_iMenuPosition[id]);
	
	return PLUGIN_HANDLED;
}

DisplayGagMenu(id, iPos)
{
	if (iPos < 0)
	{
		if (get_pcvar_num(g_pMenuEnabled))
			menu_display(id, g_hMainMenu, 0);
		return;
	}

	g_iMenuPlayers[id] = GetMenuPlayers(g_iMenuPlayersNum[id], GAG);
	g_iMenu[id] = GAG;

	new szMenuBody[1024];
	new b = 0;
	new i;
	new szName[32];
	new iStart = iPos * 6;
	
	if (iStart >= g_iMenuPlayersNum[id])
		iStart = iPos = g_iMenuPosition[id] = 0;
	
	new szKey[20];
	format(szKey, charsmax(szKey), "AMXSUPER_MENU%d", GAG);
	new iLen = format(szMenuBody, 1023, "\y%L\R%d/%d^n\w^n", id, szKey, iPos + 1, (g_iMenuPlayersNum[id] / 6 + ((g_iMenuPlayersNum[id] % 6) ? 1 : 0)));
	new iEnd = iStart + 6;
	new iKeys = MENU_KEY_0|MENU_KEY_7|MENU_KEY_8;

	if (iEnd > g_iMenuPlayersNum[id])
		iEnd = g_iMenuPlayersNum[id];

	for (new a = iStart; a < iEnd; ++a)
	{
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, 31);
		/*
		switch (i)
		{
			case 33: format(szName, charsmax(szName), "%L", id, "AMXSUPER_ALL");
			case 34: format(szName, charsmax(szName), "%L", id, "AMXSUPER_TEAMT");
			case 35: format(szName, charsmax(szName), "%L", id, "AMXSUPER_TEAMCT");
			default: get_user_name(i, szName, 31);
		}
		*/
		
		if (i < 33 && i != id && access(i, ADMIN_IMMUNITY))
		{
			++b;
			iLen += format(szMenuBody[iLen], 1023-iLen, "\d\r%d. \w%s^n\w", b, szName);
		} else {
			iKeys |= (1<<b);
				
			if (i < 33 && is_user_admin(i))
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r%d. \w%s \r*^n\w", ++b, szName);
			else
				iLen += format(szMenuBody[iLen], 1023-iLen, "\r%d. \w%s^n", ++b, szName);
		}
	}
	
	new szOption[20];
	format(szOption, charsmax(szOption), "%d", ArrayGetCell(Array:g_aValueArray[g_iMenu[id]], g_iMenuProperties[id]));
	iLen += format(szMenuBody[iLen], 1023-iLen, "7. %L^n", id, "AMXSUPER_MINS", szOption);
	
	switch (g_iMenuProperties2[id])
	{
		case 0: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L^n", id, "AMXSUPER_GAGA");
		case 1: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L^n", id, "AMXSUPER_GAGB");
		case 2: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L^n", id, "AMXSUPER_GAGC");
		case 3: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L & %L^n", id, "AMXSUPER_GAGA", id, "AMXSUPER_GAGB");
		case 4: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L & %L^n", id, "AMXSUPER_GAGA", id, "AMXSUPER_GAGC");
		case 5: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L & %L^n", id, "AMXSUPER_GAGB", id, "AMXSUPER_GAGC");
		case 6: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L & %L & %L^n", id, "AMXSUPER_GAGA", id, "AMXSUPER_GAGB", id, "AMXSUPER_GAGC");
		case 7: iLen += format(szMenuBody[iLen], 1023-iLen, "8. %L^n", id, "AMXSUPER_UNGAG");
	}
	
	if (iEnd != g_iMenuPlayersNum[id])
	{
		format(szMenuBody[iLen], 1023-iLen, "^n9. %L...^n0. %L", id, "MORE", id, iPos ? "BACK" : "EXIT");
		iKeys |= MENU_KEY_9;
	}
	else
		format(szMenuBody[iLen], 1023-iLen, "^n0. %L", id, iPos ? "BACK" : "EXIT");

	show_menu(id, iKeys, szMenuBody, -1, "Gag Menu");
}
