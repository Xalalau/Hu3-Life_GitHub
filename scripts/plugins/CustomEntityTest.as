class CPluginEntity : CCustomCBaseEntity
{
	void OnCreate()
	{
		BaseClass.OnCreate();
		Engine.Alert( at_console, "Created custom entity %1\n", self.GetClassname() );
		
		Entity::Remove( this );
	}
	
	void OnDestroy()
	{
		Engine.Alert( at_console, "Destroying custom entity %1\n", self.GetClassname() );
	
		BaseClass.OnDestroy();
	}
	
	~CPluginEntity()
	{
	}
}

void MapInit()
{
	g_CustomEntities.RegisterCustomEntity( "custom_plugin_entity", "CPluginEntity" );
	
	CBaseEntity@ pEntity = g_CustomEntities.CreateCustomEntity( "custom_plugin_entity" );
	
	CPluginEntity@ pEnt = cast<CPluginEntity@>( CustomEnts::Cast( pEntity ) );
	
	Engine.Alert( at_console, "Entity is non-null: %1\n", pEnt !is null );
	
	//g_CustomEntities.UnregisterCustomEntity( "custom_plugin_entity", "CPluginEntity" );
}
