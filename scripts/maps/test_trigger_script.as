void ConMsg( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	Engine.Alert( at_console, "Entity %1 activated this message, Entity %2 called it\n", pActivator.GetClassname(), pCaller.GetClassname() );
}

void Thinker()
{
	Engine.Alert( at_console, "Thinking at %1\n", Globals.time );
}

#if SERVER_DLL
void Thinker2(ThinkState::ThinkState state)
{
	Engine.Alert( at_console, "Thinking state: %1(%2) %3\n", ThinkState::ToString( state ), int( state ), int( ThinkState::FromString( ThinkState::ToString( state ) ) ) );
}
#endif

void PluginMessage( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	Engine.Alert( at_console, "Map script got triggered by a trigger_script that should be plugin only: Player %1 activated it\n", pActivator.GetNetName() );
}
