#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <pug>

#define TASK_MENUCLOSE 9001
#define TASK_PLAYERSLIST 9002

#define MinPlayers 10

new const TAG[] = "^4[^1TEST^4]^1"

native RemoveTask1()
native Pregame()

new RandomPlayer1;
new RandomPlayer2;

new bool:CaptainSort;

public plugin_init()
{
	register_plugin("Captain Sorting", "1.0", "kramesa");

	register_clcmd("chooseteam", "Block");
	register_clcmd("jointeam", "Block");
}

public plugin_natives()
{
	register_native("Capitan", "pugcapitan")
}

public pugcapitan()
{
	return Captain()
}

public Block(id)
{
	if(CaptainSort == true)
	{
		client_print_color(id, id, "%s Espera a que los capitanes eligan a sus jugadores", TAG);
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public client_putinserver(id) 
{
	if(!is_user_connected(RandomPlayer1) && CaptainSort)
	{
		RandomPlayer1 = id;

		new First_Captain[35];
		get_user_name(RandomPlayer1, First_Captain, charsmax(First_Captain));

		client_print_color(0, print_team_grey, "%s El nuevo capitan de los CT es: ^3%s", TAG, First_Captain);
		set_cvar_num("sv_restartround", 1);
	}
	if(!is_user_connected(RandomPlayer2) && CaptainSort)
	{
		RandomPlayer2 = id;

		new Second_Captain[35];
		get_user_name(RandomPlayer2, Second_Captain, charsmax(Second_Captain));

		client_print_color(0, print_team_grey, "%s El nuevo capitan de los TT es: ^3%s", TAG, Second_Captain);
		set_cvar_num("sv_restartround", 1)
	}
}

public Captain()
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ch");

	if(iNum < MinPlayers)
	{
		client_print_color(0, 0, "%s Necesitas tener mas de ^4%d ^1jugadores para la eleccion de capitanes", TAG, (MinPlayers));
		Pregame()
		return PLUGIN_HANDLED;
	}
	for(new i; i < iNum; i++)
	{
		user_silentkill(iPlayers[i]);
		cs_set_user_team(iPlayers[i], 3);
	}
	RandomPlayer1 = iPlayers[random(iNum)];
	RandomPlayer2 = iPlayers[random(iNum)];

	while(RandomPlayer1 == RandomPlayer2)
	{
		RandomPlayer2 = iPlayers[random(iNum)];
	}
	cs_set_user_team(RandomPlayer1, CS_TEAM_CT);
	cs_set_user_team(RandomPlayer2, CS_TEAM_T);

	new First_Captain[35], Second_Captain[35];

	get_user_name(RandomPlayer1, First_Captain, charsmax(First_Captain));
	get_user_name(RandomPlayer2, Second_Captain, charsmax(Second_Captain));

	client_print_color(0, print_team_grey, "%s Los capitanes son: ^3%s ^4(^1TT^4) ^1y ^3%s ^4(^1CT^4)", TAG, First_Captain, Second_Captain);
	client_print_color(0, 0, "%s Si no eligen un jugador en 10 segundos un jugador sera elegido aleatoriamente", TAG);

	set_cvar_num("sv_restartround", 1)

	new First = random(2)

	set_task(1.5, "captain_menu", First ? RandomPlayer1 : RandomPlayer2);
	set_task(0.2, "PlayersList", TASK_PLAYERSLIST, _, _, "b");

	RemoveTask1()
	CaptainSort = true
	return PLUGIN_CONTINUE
}

public captain_menu(id)
{
	new menu = menu_create("\ySelecciona un Jugador", "captainmenu_handler")

	set_task(11.5, "menu_task", id + TASK_MENUCLOSE);

	new players[32], pnum, tempid;
	new szName[32], szTempid[10];

	get_players(players, pnum, "ch")

	if(pnum == 0)
	{
		remove_task(id+TASK_MENUCLOSE)
		remove_task(TASK_PLAYERSLIST)
		CaptainSort = false
		Pregame()

		client_print_color(0, 0, "%s Modo capitan cancelado, jugadores desaparecidos", TAG);
		return PLUGIN_HANDLED;
	}
	for(new i; i<pnum; i++)
	{
		tempid = players[i];

		if(cs_get_user_team(tempid) != CS_TEAM_SPECTATOR) continue;

		get_user_name(tempid, szName, charsmax(szName));
		num_to_str(tempid, szTempid, charsmax(szTempid));

		menu_additem(menu, szName, szTempid,0);
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public captainmenu_handler(id,menu,item)
{
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);

	new tempid = str_to_num(data)

	new name[35], namec[35];
	get_user_name(tempid, name, charsmax(name));
	get_user_name(id, namec, charsmax(namec));

	cs_set_user_team(tempid, cs_get_user_team(id));
	client_print_color(0, print_team_grey, "%s ^3%s ^1elige al jugador ^3%s", TAG, namec, name);

	set_cvar_num("sv_restart",1)

	remove_task(id+TASK_MENUCLOSE)

	new iPlayers[32],pnum
	get_players(iPlayers,pnum,"h")

	if(is_user_connected(RandomPlayer1) && is_user_connected(RandomPlayer2))
	{
		set_task(1.5,"captain_menu",id == RandomPlayer1 ? RandomPlayer2 : RandomPlayer1)
	}
	else
	{
		set_task(5.0,"CheckCaptainJoin",id == RandomPlayer1 ? RandomPlayer1 : RandomPlayer2)
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public menu_task(id)
{
	id -= TASK_MENUCLOSE

	new players[32], pnum;
	get_players(players, pnum, "ch");

	new randomnum = random(pnum)
	new bool:has_spec

	for(new i; i < pnum; i++)
	{
		if(cs_get_user_team(players[i]) == CS_TEAM_SPECTATOR)
		{
			has_spec = true
		}
	}
	if(!has_spec)
	{
		remove_task(TASK_PLAYERSLIST);
		PugNextVote()
		CaptainSort = false;
		return;
	}
	while(cs_get_user_team(players[randomnum]) != CS_TEAM_SPECTATOR)
	{
		randomnum = random(pnum)
	}
	if(is_user_connected(id))
	{
		set_cvar_num("sv_restart",1)
		cs_set_user_team(players[randomnum],cs_get_user_team(id))

		set_task(1.5, "captain_menu", id == RandomPlayer1 ? RandomPlayer2 : RandomPlayer1);
	}
	else
	{
		set_task(5.0, "CheckCaptainJoin", id == RandomPlayer1 ? RandomPlayer2 : RandomPlayer1);

		client_print_color(0, 0, "%s Esperando un nuevo capitan", TAG);
	}
	show_menu(id, 0, "^n", 1);
}

public CheckCaptainJoin(NextCaptainMenu)
{
	if(is_user_connected(RandomPlayer1) && is_user_connected(RandomPlayer2))
	{
		set_task(1.5, "captain_menu", NextCaptainMenu)
	}
	else
	{
		set_task(5.0, "CheckCaptainJoin", NextCaptainMenu)
	}
}

public PlayersList()
{
	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ch");

	new posTR, posCT, posSPEC;
	new HudTextTR[512], HudTextCT[512], HudTextSPEC[512];
	new szName[38], name[38];

	for(new i; i < iNum; i++)
	{
		get_user_name(iPlayers[i], szName, charsmax(szName));

		if(iPlayers[i] == RandomPlayer1 || iPlayers[i] == RandomPlayer2)
		{
			formatex(name, charsmax(name), "%s (C)", szName);
		}
		else
		{
			name = szName;
		}
		if(cs_get_user_team(iPlayers[i]) == CS_TEAM_T)
		{
			posTR += formatex(HudTextTR[posTR], 511-posTR,"%s^n", name);
		}
		else if(cs_get_user_team(iPlayers[i]) == CS_TEAM_CT)
		{
			posCT += formatex(HudTextCT[posCT], 511-posCT, "%s^n", name);
		}
		else
		{
			posSPEC += formatex(HudTextSPEC[posSPEC], 511-posSPEC, "%s^n", name);
		}
	}
	for(new i; i < iNum; i++)
	{
		set_hudmessage(255, 0, 0, 0.70, 0.16, 0, 0.0, 1.1, 0.0, 0.0, 1);
		show_hudmessage(iPlayers[i], "Terroristas");

		set_hudmessage(255, 255, 255, 0.70, 0.19, 0, 0.0, 1.1, 0.0, 0.0, 2);
		show_hudmessage(iPlayers[i], HudTextTR);

		set_hudmessage(0, 0, 255, 0.70, 0.51, 0, 0.0, 1.1, 0.0, 0.0, 3);
		show_hudmessage(iPlayers[i], "AntiTerroristas");

		set_hudmessage(255, 255, 255, 0.70, 0.54, 0, 0.0, 1.1, 0.0, 0.0, 4);
		show_hudmessage(iPlayers[i], HudTextCT);
	}
} 
