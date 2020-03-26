/* * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * AMX Super - Command Manager
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
 *   AMX Super - Command Manager (amx_super-cmdmanager.sma)
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
 
 #include <amxmodx>
#include <amxmisc>

#pragma semicolon 1
#define VERSION	"5.0.2"

new const g_szDisabledCmdsFilename[] = "disabled_cmds.ini";

new const g_szCmdList[][] = {
	"amx_heal",		
	"amx_armor",			
	"amx_teleport",		
	"amx_userorigin",	
	"amx_stack",			
	"amx_gravity",			
	"amx_unammo",		
	"amx_weapon",
	"amx_weaponmenu",
	"amx_drug",			
	"amx_godmode",			
	"amx_setmoney",		
	"amx_noclip",			
	"amx_speed",			
	"amx_revive",			
	"amx_bury",			
	"amx_unbury",			
	"amx_disarm",		
	"amx_slay2",		
	"amx_rocket",			
	"amx_fire",		
	"amx_flash",	
	"amx_uberslap",
	"amx_glow",
	"amx_glow2",	
	"amx_glowcolors",	
	"amx_alltalk",
	"amx_extend",
	"amx_gag",
	"amx_ungag",
	"amx_pass",
	"amx_nopass",
	"amx_transfer",
	"amx_swap",
	"amx_teamswap",
	"amx_lock",
	"amx_unlock",
	"amx_badaim",
	"amx_exec",
	"amx_restart",
	"amx_shutdown",
	"say /gravity",
	"say /alltalk",
	"say /spec",
	"say /unspec",
	"say /admin",
	"say /admins",
	"say /fixsound",
	"+adminvoice"
};


new g_pLogDisabledCmds;
new Trie: g_tDisabledCmds;


public plugin_init()
{
	register_plugin("AMX Super Cmd Manager", VERSION, "SuperCentral.co");
	register_dictionary("amx_super.txt");
	
	if((g_tDisabledCmds = TrieCreate()) == Invalid_Trie)
		set_fail_state("[AMXX] Failed to create CellTrie. Please contact the authors.");
	
	for(new i = 0; i < sizeof(g_szCmdList); i++)
	{
		if(g_szCmdList[i][0] == 'a')
			register_concmd(g_szCmdList[i], "CmdConsoleCallback");
		
		else // Not a console command.
			register_clcmd(g_szCmdList[i], "CmdClientCallback");
	}
	
	g_pLogDisabledCmds = register_cvar("amx_logdisabledcmds", "1");

	register_concmd("amx_reloadcmds", "CmdReloadCmds", ADMIN_CVAR, "Reloads all amx super commands. (see disabled_cmds.ini)");
	
	// Call it once manually to load the commands on map change.
	CmdReloadCmds(0, 0, 0);
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

	
public CmdReloadCmds(id, iLevel, iCid)
{
	if(id)
	{
		if(cmd_access(id, iLevel, iCid, 1))
		{
			new szName[35], szSteamid[35];
			get_user_name(id, szName, charsmax(szName));
			get_user_authid(id, szSteamid, charsmax(szSteamid));
			
			show_activity_key("AMX_SUPER_CMDMGR_RELOAD_CASE1", "AMX_SUPER_CMDMGR_RELOAD_CASE2", szName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_CMDMGR_RELOAD_LOG", szName, szSteamid);
		}
		
		else
			return PLUGIN_HANDLED;
	}
	
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
	
		else
			log_amx("%L", LANG_SERVER, "AMX_SUPER_CMDMGR_FILE_FAILED", g_szDisabledCmdsFilename);
	}
	
	else // file doesn't exist, make new one.
	{
		if((iFile = fopen(szDisabledCmdFile, "wt")))
		{
			fprintf(iFile, "; disabled_cmds.ini		Created by amx_super 5.0^n");
			fprintf(iFile, "; Commands added in this file will not be registered by amx super, thus will be disabled in game.^n");
			fprintf(iFile, "; 1 command per line.^n;^n; Example:^n; amx_fire");
			fclose(iFile);
		}
	}
	
	// MUST return continue so menu will also receive reload cmd.
	return PLUGIN_HANDLED_MAIN;
}


public CmdConsoleCallback(id)
{
	new szCmd[64];
	read_argv(0, szCmd, charsmax(szCmd));
	
	if(TrieKeyExists(g_tDisabledCmds, szCmd))
	{
		HandleDisabledCmd(id, szCmd, true);
		
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}


public CmdClientCallback(id)
{
	new szCmd[64];
	read_argv(1, szCmd, charsmax(szCmd));
	format(szCmd, charsmax(szCmd), "say %s", szCmd);
	
	if(TrieKeyExists(g_tDisabledCmds, szCmd))
	{
		HandleDisabledCmd(id, szCmd, false);

		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}


HandleDisabledCmd(id, const szCmd[], bool: bConsole)
{
	client_print(id, bConsole ? print_console : print_chat,"%L", id, "AMX_SUPER_CMDMGR_DISABLED", szCmd); 
	
	if(get_pcvar_num(g_pLogDisabledCmds))
	{
		new szName[35], szSteamid[35];

		get_user_name(id, szName, charsmax(szName));
		get_user_authid(id, szSteamid, charsmax(szSteamid));
		
		log_amx("%L", LANG_SERVER, "AMX_SUPER_CMDMGR_DISABLED_LOG", szName, szSteamid, szCmd);
	}
}
