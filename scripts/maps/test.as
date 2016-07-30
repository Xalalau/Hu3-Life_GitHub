class CMyGameRules : CScriptGameRules
{
	void Think()
	{
	}
}

void MapInit()
{
	Engine.Alert( at_console, "Map initialized! %1\n", Globals.mapname );
}

void MapActivate()
{
	Engine.Alert( at_console, "Map activated\n" );
}

bool InstallGameRules( string& out szName )
{
	//Use my gamerules class.
	szName = "CMyGameRules";
	
	return true;
}