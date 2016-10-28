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
		Engine.Alert( at_console, "destructing custom entity %1\n", self.GetClassname() );
	}
}

void MapInit()
{
	g_CustomEntities.RegisterCustomEntity( "custom_plugin_entity", "CPluginEntity" );
	
	g_CustomEntities.CreateCustomEntity( "custom_plugin_entity" );
	
	//g_CustomEntities.UnregisterCustomEntity( "custom_plugin_entity", "CPluginEntity" );
}
