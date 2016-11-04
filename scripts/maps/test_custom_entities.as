#if SERVER_DLL
class Foo
{
	void Bar()
	{
	}
}

void Nothing()
{
}

const array<string> g_szChooseSounds = { "gman/gman_choose1.wav", "gman/gman_choose2.wav" };

namespace Ent
{
class CMyEntity : CCustomCBaseEntity
{
	void OnCreate()
	{
		BaseClass.OnCreate();
		Engine.Alert( at_console, "Created custom entity %1\n", self.GetClassname() );
		
		//Entity::Remove( this );
		SetThink( ThinkFunc( this.MyThink ) );
		self.SetNextThink( Globals.time + 1 );
		
		SetTouch( TouchFunc( this.MyTouch ) );
		
		SetUse( UseFunc( this.MyUse ) );
		SetBlocked( BlockedFunc( this.MyBlocked ) );
		
		self.SetSolidType( SOLID_BBOX );
		self.SetSize( Vector( -16, -16, -16 ), Vector( 16, 16, 16 ) );
		self.SetModel( "models/player.mdl" );
		self.SetAbsOrigin( Vector( 128, 128, 64 ) );
		self.SetMoveType( MOVETYPE_FLY );
		
		self.SetTargetname( "customent" );
		
		Precache();
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
	
	void Precache()
	{
		BaseClass.Precache();
		
		g_engfuncs.PrecacheModel( "models/player.mdl" );
		
		SoundSystem.PrecacheSound( "nihilanth/nil_freeman.wav" );
		
		for( uint uiIndex = 0; uiIndex < g_szChooseSounds.length(); ++uiIndex )
		{
			SoundSystem.PrecacheSound( g_szChooseSounds[ uiIndex ] );
		}
	}
	
	/*
	void Think()
	{
		Engine.Alert( at_console, "overridden think\n" );
		
		self.SetNextThink( Globals.time + 1 );
	}
	*/
	
	void MyThink()
	{
		Engine.Alert( at_console, "my think\n" );
		
		self.SetNextThink( Globals.time + 5 );
		
		SoundSystem.EmitSoundDyn( self, SoundChan::VOICE, "nihilanth/nil_freeman.wav", 1, Attn::NORM, 0, 150 );
	}
	
	void MyTouch( CBaseEntity@ pOther )
	{
		Engine.Alert( at_console, "my touch\n" );
		
		SoundSystem.EmitSoundDyn( self, SoundChan::BODY, "nihilanth/nil_freeman.wav", 1, Attn::NORM, 0, 50 );
		
		SoundSystem.TextureType_PlaySound( Util::GetGlobalTrace(), self.GetAbsOrigin(), self.GetAbsOrigin() + Vector( 0, 0, -128 ), Bullet::PLAYER_9MM );
	}
	
	void MyUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		Engine.Alert( at_console, "my use\n" );
		
		if( pActivator !is null && pActivator.IsPlayer() )
		{
			//SoundSystem.EmitGroupNameSuit( self, "HEV_A" );
			
			SoundSystem.EmitSoundDyn( self, SoundChan::WEAPON, "nihilanth/nil_freeman.wav", 1, Attn::NORM, 0, 100 );
			
			//SoundSystem.EmitAmbientSound( self, self.GetAbsOrigin() + Vector( 512, 512, 0 ), g_szChooseSounds[ RandomLong( 0, g_szChooseSounds.length() - 1 ) ], 1, Attn::NORM, 0, 100 );
			
			Effects::ParticleEffect( ( pCaller.GetAbsMax() + pCaller.GetAbsMin() ) / 2 + Vector( 0, 0, 64 ), Vector( 0, 0, 10 ), 255, 20 );
			
			const string szAlphabet = "abcdefghijklmniopqrstuvwxyz";
			
			string szStyle;
			
			for( uint uiIndex = 0; uiIndex < 10; ++uiIndex )
			{
				szStyle += szAlphabet.substr( Math::RandomLong( 0, szAlphabet.length() - 1 ), 1 );
			}
			
			Effects::LightStyle( 0, szStyle );
		}
	}
	
	void MyBlocked( CBaseEntity@ pOther )
	{
		Engine.Alert( at_console, "my blocked\n" );
	}
}
}
#endif

void MapInit()
{
#if SERVER_DLL
	g_CustomEntities.RegisterCustomEntity( "my_entity", "Ent::CMyEntity" );
	
	//g_CustomEntities.UnregisterCustomEntity( "my_entity", "Ent::CMyEntity" );
#endif
}

void MapActivate()
{
#if SERVER_DLL
	CBaseEntity@ pEntity = g_CustomEntities.CreateCustomEntity( "my_entity" );
	
	CBaseEntity@ pWorld = Entity::EntityFromIndex( 0 );
	
	Vector vecOrigin( 512, 512, 1 );
	
	Effects::StaticDecal( vecOrigin, Util::DecalIndex( "{SCORCH1" ), pWorld.entindex(), pWorld.GetModelIndex() );
	
	g_engfuncs.ServerPrint( "Printing formatted string to server console: %1 %2 %3 \n", pWorld.GetAbsMin().ToString(), pWorld.GetAbsMax().ToString(), pWorld.GetClassname() );
#endif
}
