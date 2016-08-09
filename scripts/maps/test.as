
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

#if SERVER_DLL
SQLiteConnection@ g_pSQLiteConnection = null;
MySQLConnection@ g_pMySQLConnection = null;

void CreateSQLConnection()
{
	@g_pSQLiteConnection = SQL::CreateSQLiteConnection( "testdb" );
	
	g_pSQLiteConnection.Query(
		"CREATE TABLE IF NOT EXISTS TestTable("
		"ID INT PRIMARY KEY NOT NULL"
		")",
		SQLiteQueryCompleted
	);
	
	@g_pMySQLConnection = SQL::CreateMySQLConnection( "localhost", "root", "", "TestDB" );
	
	g_pMySQLConnection.Query( "SELECT * FROM Test", MySQLQueryCompleted );
}

void SQLiteQueryCompleted( SQLiteQuery@ pQuery )
{
	Engine.Alert( at_console, "SQLite Query completed\n" );
}

void MySQLQueryCompleted( MySQLQuery@ pQuery )
{
	Engine.Alert( at_console, "MySQL Query completed\n" );
}
#endif

void MapInit()
{
	Engine.Alert( at_console, "Map initialized! %1\n", Globals.mapname );
	
#if SERVER_DLL
	CreateSQLConnection();
#endif
}

void MapActivate()
{
	Engine.Alert( at_console, "Map activated\n" );
}