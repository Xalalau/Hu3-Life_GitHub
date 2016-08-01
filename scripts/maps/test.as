
#if SERVER_DLL
class CMyGameRules : CScriptGameRules
{
	void Think()
	{
	}
}

bool InstallGameRules( string& out szName )
{
	//Use my gamerules class.
	szName = "CMyGameRules";
	
	return true;
}
#endif

void MapInit()
{
	Engine.Alert( at_console, "Map initialized! %1\n", Globals.mapname );
}

void MapActivate()
{
	Engine.Alert( at_console, "Map activated\n" );
}