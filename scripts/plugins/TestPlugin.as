#include "SecondScript"
#include "../SharedScript"

void PluginInit()
{
	Engine.Alert( at_console, "Plugin init\n" );
	
	Engine.Alert( at_console, "My old lifetime: %1\n", PluginLifetime::ToString( PluginData.GetLifetime() ) );
	
	PluginData.SetMinimumLifetime( PluginLifetime::MAP );
	
	Engine.Alert( at_console, "My new lifetime: %1\n", PluginLifetime::ToString( PluginData.GetLifetime() ) );
	
	Function1();
	Function2();
}

void MapInit()
{
	Engine.Alert( at_console, "Map init\n" );
}

void MapActivate()
{
	Engine.Alert( at_console, "Map activated\n" );
}

void MapShutdown()
{
	Engine.Alert( at_console, "Map shutdown\n" );
}

void PluginUnload()
{
	Engine.Alert( at_console, "Unloading thyself %1\n", PluginData.GetName() );
}