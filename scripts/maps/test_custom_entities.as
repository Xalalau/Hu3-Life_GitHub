#if SERVER_DLL
namespace Ent
{
class CMyEntity : CCustomCBaseEntity
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
	
	~CMyEntity()
	{
		Engine.Alert( at_console, "destructing custom entity %1\n", self.GetClassname() );
	}
}
}
#endif

void MapInit()
{
#if SERVER_DLL
	g_CustomEntities.RegisterCustomEntity( "my_entity", "Ent::CMyEntity" );
	
	g_CustomEntities.CreateCustomEntity( "my_entity" );
	
	//g_CustomEntities.UnregisterCustomEntity( "my_entity", "Ent::CMyEntity" );
#endif
}
