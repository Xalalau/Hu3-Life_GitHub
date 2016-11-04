/*
*	This file defines the custom entity named func_vehicle_custom
*	This is a simple, player controllable vehicle
*
*	DO NOT ALTER THIS FILE
*/

const double VEHICLE_SPEED0_ACCELERATION = 0.005000000000000000;
const double VEHICLE_SPEED1_ACCELERATION = 0.002142857142857143;
const double VEHICLE_SPEED2_ACCELERATION = 0.003333333333333334;
const double VEHICLE_SPEED3_ACCELERATION = 0.004166666666666667;
const double VEHICLE_SPEED4_ACCELERATION = 0.004000000000000000;
const double VEHICLE_SPEED5_ACCELERATION = 0.003800000000000000;
const double VEHICLE_SPEED6_ACCELERATION = 0.004500000000000000;
const double VEHICLE_SPEED7_ACCELERATION = 0.004250000000000000;
const double VEHICLE_SPEED8_ACCELERATION = 0.002666666666666667;
const double VEHICLE_SPEED9_ACCELERATION = 0.002285714285714286;
const double VEHICLE_SPEED10_ACCELERATION = 0.001875000000000000;
const double VEHICLE_SPEED11_ACCELERATION = 0.001444444444444444;
const double VEHICLE_SPEED12_ACCELERATION = 0.001200000000000000;
const double VEHICLE_SPEED13_ACCELERATION = 0.000916666666666666;
const double VEHICLE_SPEED14_ACCELERATION = 0.001444444444444444;

const int VEHICLE_STARTPITCH = 60;
const int VEHICLE_MAXPITCH = 200;
const int VEHICLE_MAXSPEED = 1500;

enum FuncVehicleFlags
{
	SF_VEHICLE_NODEFAULTCONTROLS = 1 << 0 //Don't make a controls volume by default
}

class func_vehicle_custom : CCustomCBaseEntity
{
	//TODO: temporary until code is switched over to the method below. - Solokiller
	void KeyValue( KeyValueData@ pkvd )
	{
		if( KeyValue( pkvd.szKeyName, pkvd.szValue ) )
			pkvd.bHandled = true;
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "length")
		{
			m_length = atof(szValue);
			return true;
		}
		else if (szKey == "width")
		{
			m_width = atof(szValue);
			return true;
		}
		else if (szKey == "height")
		{
			m_height = atof(szValue);
			return true;
		}
		else if (szKey == "startspeed")
		{
			m_startSpeed = atof(szValue);
			return true;
		}
		else if (szKey == "sounds")
		{
			m_sounds = atoi(szValue);
			return true;
		}
		else if (szKey == "volume")
		{
			m_flVolume = float(atoi(szValue));
			m_flVolume *= 0.1;
			return true;
		}
		else if (szKey == "bank")
		{
			m_flBank = atof(szValue);
			return true;
		}
		else if (szKey == "acceleration")
		{
			m_acceleration = atoi(szValue);

			if (m_acceleration < 1)
				m_acceleration = 1;
			else if (m_acceleration > 10)
				m_acceleration = 10;

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void NextThink(float thinkTime, const bool alwaysThink)
	{
		if (alwaysThink)
			self.GetFlags() |= FL_ALWAYSTHINK;
		else
			self.GetFlags() &= int( ~FL_ALWAYSTHINK );

		self.SetNextThink( thinkTime );
	}
	
	void Blocked(CBaseEntity@ pOther)
	{
		if (pOther.GetFlags().Any(FL_ONGROUND) && pOther.GetGroundEntity() !is null && pOther.GetGroundEntity() is self )
		{
			pOther.SetAbsVelocity( self.GetAbsVelocity() );
			return;
		}
		else
		{
			Vector vecVelocity( (pOther.GetAbsOrigin() - self.GetAbsOrigin()).Normalize() * self.GetDamage() );
			vecVelocity.z += 300;
			vecVelocity = vecVelocity * 0.85;
			
			pOther.SetAbsVelocity( vecVelocity );
		}

		Engine.Alert(at_aiconsole, "TRAIN(%1): Blocked by %2 (dmg:%3)\n", self.GetTargetname(), pOther.GetClassname(), self.GetDamage());
		Math::MakeVectors(self.GetAbsAngles());

		Vector vFrontLeft = (Globals.v_forward * -1) * (m_length * 0.5);
		Vector vFrontRight = (Globals.v_right * -1) * (m_width * 0.5);
		Vector vBackLeft = self.GetAbsOrigin() + vFrontLeft - vFrontRight;
		Vector vBackRight = self.GetAbsOrigin() - vFrontLeft + vFrontRight;
		float minx = min(vBackLeft.x, vBackRight.x);
		float maxx = max(vBackLeft.x, vBackRight.x);
		float miny = min(vBackLeft.y, vBackRight.y);
		float maxy = max(vBackLeft.y, vBackRight.y);
		float minz = self.GetAbsOrigin().z;
		float maxz = self.GetAbsOrigin().z + (2 * abs(int(self.GetRelMin().z - self.GetRelMax().z)));
		
		const Vector vecOrigin = pOther.GetAbsOrigin();

		if (vecOrigin.x < minx || vecOrigin.x > maxx || vecOrigin.y < miny || vecOrigin.y > maxy || vecOrigin.z < minz || vecOrigin.z > maxz)
			pOther.TakeDamage(self, self, 150, Dmg::CRUSH);
	}

	void Spawn()
	{
		if (self.GetSpeed() == 0)
			m_speed = 165;
		else
			m_speed = self.GetSpeed();

		if (m_sounds == 0)
			m_sounds = 3;

		Engine.Alert(at_console, "M_speed = %1\n", m_speed);

		self.SetSpeed( 0 );
		self.SetAbsVelocity( g_vecZero );
		self.SetAngularVelocity( g_vecZero );
		self.GetImpulse().Set( int(m_speed) );
		m_acceleration = 5;
		m_dir = 1;
		m_flTurnStartTime = -1;

		if( self.GetTarget().isEmpty() )
			Engine.Alert(at_console, "Vehicle with no target\n");

		/*
		if  self.GetSpawnFlags().Any( SF_TRACKTRAIN_PASSABLE ) )
			self.SetSolidType( SOLID_NOT );
		else
		*/
			self.SetSolidType( SOLID_BSP );

		self.SetMoveType( MOVETYPE_PUSH );

		self.SetModel( self.GetModelName() );
		self.SetSize( self.GetRelMin(), self.GetRelMax() );
		self.SetAbsOrigin( self.GetAbsOrigin() );

		self.SetOldOrigin( self.GetAbsOrigin() );
		
		if( !self.GetSpawnFlags().Any( SF_VEHICLE_NODEFAULTCONTROLS ) )
		{
			m_controlMins = self.GetRelMin();
			m_controlMaxs = self.GetRelMax();
			m_controlMaxs.z += 72;
		}

		NextThink(self.GetLastThink() + 0.1, false);
		SetThink(ThinkFunc(this.Find));
		Precache();
	}

	void Restart()
	{
		Engine.Alert(at_console, "M_speed = %1\n", m_speed);

		self.SetSpeed( 0 );
		self.SetAbsVelocity( g_vecZero );
		self.SetAngularVelocity( g_vecZero );
		self.GetImpulse().Set( int(m_speed) );
		m_flTurnStartTime = -1;
		m_flUpdateSound = -1;
		m_dir = 1;
		@m_pDriver = null;

		if( self.GetTarget().isEmpty() )
			Engine.Alert(at_console, "Vehicle with no target\n");

		self.SetAbsOrigin( self.GetAbsOrigin() );
		NextThink(self.GetLastThink() + 0.1, false);
		SetThink(ThinkFunc(this.Find));
	}
	
	void Precache()
	{
		if (m_flVolume == 0)
			m_flVolume = 1;

		switch (m_sounds)
		{
			case 1: SoundSystem.PrecacheSound("plats/vehicle1.wav"); self.SetNoise( "plats/vehicle1.wav" ); break;
			case 2: SoundSystem.PrecacheSound("plats/vehicle2.wav"); self.SetNoise( "plats/vehicle2.wav" ); break;
			case 3: SoundSystem.PrecacheSound("plats/vehicle3.wav"); self.SetNoise( "plats/vehicle3.wav" ); break;
			case 4: SoundSystem.PrecacheSound("plats/vehicle4.wav"); self.SetNoise( "plats/vehicle4.wav" ); break;
			case 5: SoundSystem.PrecacheSound("plats/vehicle6.wav"); self.SetNoise( "plats/vehicle6.wav" ); break;
			case 6: SoundSystem.PrecacheSound("plats/vehicle7.wav"); self.SetNoise( "plats/vehicle7.wav" ); break;
		}

		SoundSystem.PrecacheSound("plats/vehicle_brake1.wav");
		SoundSystem.PrecacheSound("plats/vehicle_start1.wav");
		SoundSystem.PrecacheSound( "plats/vehicle_ignition.wav" );
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		float delta = value;

		if (useType != USE_SET)
		{
			if( !self.ShouldToggle( useType, self.GetSpeed() != 0 ))
				return;

			if (self.GetSpeed() == 0)
			{
				self.SetSpeed( m_speed * m_dir );
				Next();
			}
			else
			{
				self.SetSpeed( 0 );
				self.SetAbsVelocity( g_vecZero );
				self.SetAngularVelocity( g_vecZero );
				StopSound();
				SetThink(null);
			}
		}

		if (delta < 10)
		{
			if (delta < 0 && self.GetSpeed() > 145)
				StopSound();

			float flSpeedRatio = delta;

			if (delta > 0)
			{
				flSpeedRatio = self.GetSpeed() / m_speed;

				if (self.GetSpeed() < 0)
					flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + VEHICLE_SPEED0_ACCELERATION;
				else if (self.GetSpeed() < 10)
					flSpeedRatio = m_acceleration * 0.0006 + flSpeedRatio + VEHICLE_SPEED1_ACCELERATION;
				else if (self.GetSpeed() < 20)
					flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + VEHICLE_SPEED2_ACCELERATION;
				else if (self.GetSpeed() < 30)
					flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + VEHICLE_SPEED3_ACCELERATION;
				else if (self.GetSpeed() < 45)
					flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + VEHICLE_SPEED4_ACCELERATION;
				else if (self.GetSpeed() < 60)
					flSpeedRatio = m_acceleration * 0.0008 + flSpeedRatio + VEHICLE_SPEED5_ACCELERATION;
				else if (self.GetSpeed() < 80)
					flSpeedRatio = m_acceleration * 0.0008 + flSpeedRatio + VEHICLE_SPEED6_ACCELERATION;
				else if (self.GetSpeed() < 100)
					flSpeedRatio = m_acceleration * 0.0009 + flSpeedRatio + VEHICLE_SPEED7_ACCELERATION;
				else if (self.GetSpeed() < 150)
					flSpeedRatio = m_acceleration * 0.0008 + flSpeedRatio + VEHICLE_SPEED8_ACCELERATION;
				else if (self.GetSpeed() < 225)
					flSpeedRatio = m_acceleration * 0.0007 + flSpeedRatio + VEHICLE_SPEED9_ACCELERATION;
				else if (self.GetSpeed() < 300)
					flSpeedRatio = m_acceleration * 0.0006 + flSpeedRatio + VEHICLE_SPEED10_ACCELERATION;
				else if (self.GetSpeed() < 400)
					flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + VEHICLE_SPEED11_ACCELERATION;
				else if (self.GetSpeed() < 550)
					flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + VEHICLE_SPEED12_ACCELERATION;
				else if (self.GetSpeed() < 800)
					flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + VEHICLE_SPEED13_ACCELERATION;
				else
					flSpeedRatio = m_acceleration * 0.0005 + flSpeedRatio + VEHICLE_SPEED14_ACCELERATION;
			}
			else if (delta < 0)
			{
				flSpeedRatio = self.GetSpeed() / m_speed;

				if (flSpeedRatio > 0)
					flSpeedRatio -= 0.0125;
				else if (flSpeedRatio <= 0 && flSpeedRatio > -0.05)
					flSpeedRatio -= 0.0075;
				else if (flSpeedRatio <= 0.05 && flSpeedRatio > -0.1)
					flSpeedRatio -= 0.01;
				else if (flSpeedRatio <= 0.15 && flSpeedRatio > -0.15)
					flSpeedRatio -= 0.0125;
				else if (flSpeedRatio <= 0.15 && flSpeedRatio > -0.22)
					flSpeedRatio -= 0.01375;
				else if (flSpeedRatio <= 0.22 && flSpeedRatio > -0.3)
					flSpeedRatio -= - 0.0175;
				else if (flSpeedRatio <= 0.3)
					flSpeedRatio -= 0.0125;
			}

			if (flSpeedRatio > 1)
				flSpeedRatio = 1;
			else if (flSpeedRatio < -0.35)
				flSpeedRatio = -0.35;

			self.SetSpeed( m_speed * flSpeedRatio );
			Next();
			m_flAcceleratorDecay = Globals.time + 0.25;
		}
		else
		{
			if (Globals.time > m_flCanTurnNow)
			{
				if (delta == 20)
				{
					m_iTurnAngle++;
					m_flSteeringWheelDecay = Globals.time + 0.075;

					if (m_iTurnAngle > 8)
						m_iTurnAngle = 8;
				}
				else if (delta == 30)
				{
					m_iTurnAngle--;
					m_flSteeringWheelDecay = Globals.time + 0.075;

					if (m_iTurnAngle < -8)
						m_iTurnAngle = -8;
				}

				m_flCanTurnNow = Globals.time + 0.05;
			}
		}
	}
	
	int ObjectCaps() { return (BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION) | FCAP_DIRECTIONAL_USE; }
	
	void OverrideReset()
	{
		NextThink(self.GetLastThink() + 0.1, false);
		SetThink(ThinkFunc(this.NearestPath));
	}
	
	void CheckTurning()
	{
		TraceResult tr;
		Vector vecStart, vecEnd;

		if (m_iTurnAngle < 0)
		{
			if (self.GetSpeed() > 0)
			{
				vecStart = m_vFrontLeft;
				vecEnd = vecStart - Globals.v_right * 16;
			}
			else if (self.GetSpeed() < 0)
			{
				vecStart = m_vBackLeft;
				vecEnd = vecStart + Globals.v_right * 16;
			}

			Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

			if (tr.flFraction != 1)
				m_iTurnAngle = 1;
		}
		else if (m_iTurnAngle > 0)
		{
			if (self.GetSpeed() > 0)
			{
				vecStart = m_vFrontRight;
				vecEnd = vecStart + Globals.v_right * 16;
			}
			else if (self.GetSpeed() < 0)
			{
				vecStart = m_vBackRight;
				vecEnd = vecStart - Globals.v_right * 16;
			}

			Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

			if (tr.flFraction != 1)
				m_iTurnAngle = -1;
		}

		if (self.GetSpeed() <= 0)
			return;

		float speed;
		int turning = int(abs(m_iTurnAngle));

		if (turning > 4)
		{
			if (m_flTurnStartTime != -1)
			{
				float time = Globals.time - m_flTurnStartTime;

				if (time >= 0)
					speed = m_speed * 0.98;
				else if (time > 0.3)
					speed = m_speed * 0.95;
				else if (time > 0.6)
					speed = m_speed * 0.9;
				else if (time > 0.8)
					speed = m_speed * 0.8;
				else if (time > 1)
					speed = m_speed * 0.7;
				else if (time > 1.2)
					speed = m_speed * 0.5;
				else
					speed = time;
			}
			else
			{
				m_flTurnStartTime = Globals.time;
				speed = m_speed;
			}
		}
		else
		{
			m_flTurnStartTime = -1;

			if (turning > 2)
				speed = m_speed * 0.9;
			else
				speed = m_speed;
		}

		if (speed < self.GetSpeed())
			self.SetSpeed( self.GetSpeed() - ( m_speed * 0.1 ) );
	}
	
	void CollisionDetection()
	{
		TraceResult tr;
		Vector vecStart, vecEnd;
		float flDot;

		if (self.GetSpeed() < 0)
		{
			vecStart = m_vBackLeft;
			vecEnd = vecStart + (Globals.v_forward * 16);
			Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

			if (tr.flFraction != 1)
			{
				flDot = DotProduct(Globals.v_forward, tr.vecPlaneNormal * -1);

				if (flDot < 0.7 && tr.vecPlaneNormal.z < 0.1)
				{
					m_vSurfaceNormal = tr.vecPlaneNormal;
					m_vSurfaceNormal.z = 0;
					self.SetSpeed( self.GetSpeed() * 0.99 );
				}
				else if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0)
					self.SetSpeed( self.GetSpeed() * -1 );
				else
					m_vSurfaceNormal = tr.vecPlaneNormal;

				/*
				CBaseEntity@ pHit = tr.pHit;

				if (pHit !is null && pHit.Classify() == CLASS_VEHICLE)
					Engine.Alert(at_console, "I hit another vehicle\n");
					*/
			}

			vecStart = m_vBackRight;
			vecEnd = vecStart + (Globals.v_forward * 16);
			Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

			if (tr.flFraction == 1)
			{
				vecStart = m_vBack;
				vecEnd = vecStart + (Globals.v_forward * 16);
				Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

				if (tr.flFraction == 1)
					return;
			}

			flDot = DotProduct(Globals.v_forward, tr.vecPlaneNormal * -1);

			if (flDot >= 0.7)
			{
				if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0)
					self.SetSpeed( self.GetSpeed() * -1 );
				else
					m_vSurfaceNormal = tr.vecPlaneNormal;
			}
			else if (tr.vecPlaneNormal.z < 0.1)
			{
				m_vSurfaceNormal = tr.vecPlaneNormal;
				m_vSurfaceNormal.z = 0;
				self.SetSpeed( self.GetSpeed() * 0.99 );
			}
			else if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0)
				self.SetSpeed( self.GetSpeed() * -1 );
			else
				m_vSurfaceNormal = tr.vecPlaneNormal;
		}
		else if (self.GetSpeed() > 0)
		{
			vecStart = m_vFrontRight;
			vecEnd = vecStart - (Globals.v_forward * 16);
			Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::DONT_IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

			if (tr.flFraction == 1)
			{
				vecStart = m_vFrontLeft;
				vecEnd = vecStart - (Globals.v_forward * 16);
				Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

				if (tr.flFraction == 1)
				{
					vecStart = m_vFront;
					vecEnd = vecStart - (Globals.v_forward * 16);
					Util::TraceLine(vecStart, vecEnd, IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

					if (tr.flFraction == 1)
						return;
				}
			}

			flDot = DotProduct(Globals.v_forward, tr.vecPlaneNormal * -1);

			if (flDot <= -0.7)
			{
				if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0)
					self.SetSpeed( self.GetSpeed() * -1 );
				else
					m_vSurfaceNormal = tr.vecPlaneNormal;
			}
			else if (tr.vecPlaneNormal.z < 0.1)
			{
				m_vSurfaceNormal = tr.vecPlaneNormal;
				m_vSurfaceNormal.z = 0;
				self.SetSpeed( self.GetSpeed() * 0.99 );
			}
			else if (tr.vecPlaneNormal.z < 0.65 || tr.fStartSolid != 0)
				self.SetSpeed( self.GetSpeed() * -1 );
			else
				m_vSurfaceNormal = tr.vecPlaneNormal;
		}
	}

	void TerrainFollowing()
	{
		TraceResult tr;
		Util::TraceLine(self.GetAbsOrigin(), self.GetAbsOrigin() + Vector(0, 0, (m_height + 48) * -1), IgnoreMonsters::IGNORE_MONSTERS, IgnoreGlass::DONT_IGNORE_GLASS, self, tr);

		if (tr.flFraction != 1)
			m_vSurfaceNormal = tr.vecPlaneNormal;
		else if( tr.fInWater != 0 )
			m_vSurfaceNormal = Vector(0, 0, 1);
	}

	void Next()
	{
		Vector vGravityVector = g_vecZero;
		Math::MakeVectors(self.GetAbsAngles());

		Vector forward = (Globals.v_forward * -1) * (m_length * 0.5);
		Vector right = (Globals.v_right * -1) * (m_width * 0.5);
		Vector up = Globals.v_up * 16;

		m_vFrontRight = self.GetAbsOrigin() + forward - right + up;
		m_vFrontLeft = self.GetAbsOrigin() + forward + right + up;
		m_vFront = self.GetAbsOrigin() + forward + up;
		m_vBackLeft = self.GetAbsOrigin() - forward - right + up;
		m_vBackRight = self.GetAbsOrigin() - forward + right + up;
		m_vBack = self.GetAbsOrigin() - forward + up;
		m_vSurfaceNormal = g_vecZero;

		CheckTurning();

		if (Globals.time > m_flSteeringWheelDecay)
		{
			m_flSteeringWheelDecay = Globals.time + 0.1;

			if (m_iTurnAngle < 0)
				m_iTurnAngle++;
			else if (m_iTurnAngle > 0)
				m_iTurnAngle--;
		}

		if (Globals.time > m_flAcceleratorDecay and m_flLaunchTime == -1)
		{
			if (self.GetSpeed() < 0)
			{
				self.SetSpeed( self.GetSpeed() + 20 );

				if (self.GetSpeed() > 0)
					self.SetSpeed( 0 );
			}
			else if (self.GetSpeed() > 0)
			{
				self.SetSpeed( self.GetSpeed() - 20 );

				if (self.GetSpeed() < 0)
					self.SetSpeed( 0 );
			}
		}
		
		//Moved here to make sure sounds are always handled correctly
		if (Globals.time > m_flUpdateSound)
		{
			UpdateSound();
			m_flUpdateSound = Globals.time + 1;
		}

		if (self.GetSpeed() == 0)
		{
			m_iTurnAngle = 0;
			self.SetAngularVelocity( g_vecZero );
			self.SetAbsVelocity( g_vecZero );
			SetThink(ThinkFunc(this.Next));
			NextThink(self.GetLastThink() + 0.1, true);
			return;
		}

		TerrainFollowing();
		CollisionDetection();

		if (m_vSurfaceNormal == g_vecZero)
		{
			if (m_flLaunchTime != -1)
			{
				vGravityVector = Vector(0, 0, 0);
				vGravityVector.z = (Globals.time - m_flLaunchTime) * -35;

				if (vGravityVector.z < -400)
					vGravityVector.z = -400;
			}
			else
			{
				m_flLaunchTime = Globals.time;
				vGravityVector = Vector(0, 0, 0);
				self.SetAbsVelocity( self.GetAbsVelocity() * 1.5 );
			}

			m_vVehicleDirection = Globals.v_forward * -1;
		}
		else
		{
			m_vVehicleDirection = CrossProduct(m_vSurfaceNormal, Globals.v_forward);
			m_vVehicleDirection = CrossProduct(m_vSurfaceNormal, m_vVehicleDirection);

			Vector angles = Math::VecToAngles(m_vVehicleDirection);
			angles.y += 180;

			if (m_iTurnAngle != 0)
				angles.y += m_iTurnAngle;

			angles = FixupAngles(angles);
			self.SetAbsAngles( FixupAngles( self.GetAbsAngles() ) );

			float vx = Math::AngleDistance(angles.x, self.GetAbsAngles().x);
			float vy = Math::AngleDistance(angles.y, self.GetAbsAngles().y);

			if (vx > 10)
				vx = 10;
			else if (vx < -10)
				vx = -10;

			if (vy > 10)
				vy = 10;
			else if (vy < -10)
				vy = -10;
				
			Vector vecAVel = self.GetAngularVelocity();

			vecAVel.y = int(vy * 10);
			vecAVel.x = int(vx * 10);
			
			self.SetAngularVelocity( vecAVel );
			m_flLaunchTime = -1;
			m_flLastNormalZ = m_vSurfaceNormal.z;
		}

		Math::VecToAngles(m_vVehicleDirection);

		/*
		if (Globals.time > m_flUpdateSound)
		{
			UpdateSound();
			m_flUpdateSound = Globals.time + 1;
		}
		*/

		if (m_vSurfaceNormal == g_vecZero)
			self.SetAbsVelocity( self.GetAbsVelocity() + vGravityVector );
		else
			self.SetAbsVelocity( m_vVehicleDirection.Normalize() * self.GetSpeed() );

		SetThink(ThinkFunc(this.Next));
		NextThink(self.GetLastThink() + 0.1, true);
	}

	void Find()
	{
		@m_ppath = cast<CPathTrack@>( Entity::FindEntityByTargetname( null, self.GetTarget() ) );

		if (m_ppath is null)
			return;

		if (!m_ppath.ClassnameIs( "path_track" ))
		{
			Engine.Alert(at_error, "func_vehicle_custom must be on a path of path_track\n");
			@m_ppath = null;
			return;
		}

		Vector nextPos = m_ppath.GetAbsOrigin();
		nextPos.z += m_height;

		Vector look = nextPos;
		look.z -= m_height;
		m_ppath.LookAhead(look, look, m_length, true);
		look.z += m_height;

		Vector vecAngles = Math::VecToAngles(look - nextPos);
		vecAngles.y += 180;

		/*
		if( self.GetSpawnFlags().Any( SF_TRACKTRAIN_NOPITCH ) )
			vecAngles.x = 0;
			*/
			
		self.SetAbsAngles( vecAngles );

		self.SetAbsOrigin( nextPos );
		NextThink(self.GetLastThink() + 0.1, false);
		SetThink(ThinkFunc(this.Next));
		self.SetSpeed( m_startSpeed );
		UpdateSound();
	}

	void NearestPath()
	{
		CBaseEntity@ pTrack = null;
		CBaseEntity@ pNearest = null;
		float dist = 0.0f;
		float closest = 1024;

		while ((@pTrack = @Entity::FindEntityInSphere(pTrack, self.GetAbsOrigin(), 1024)) !is null)
		{
			if ((pTrack.GetFlags() & (FL_CLIENT | FL_MONSTER)) == 0 && pTrack.ClassnameIs( "path_track" ))
			{
				dist = (self.GetAbsOrigin() - pTrack.GetAbsOrigin()).Length();

				if (dist < closest)
				{
					closest = dist;
					@pNearest = @pTrack;
				}
			}
		}

		if (pNearest is null)
		{
			Engine.Alert(at_console, "Can't find a nearby track !!!\n");
			SetThink(null);
			return;
		}

		Engine.Alert(at_aiconsole, "TRAIN: %1, Nearest track is %2\n", self.GetTargetname(), pNearest.GetTargetname());
		@pTrack = cast<CPathTrack@>(pNearest).GetNext();

		if (pTrack !is null)
		{
			if ((self.GetAbsOrigin() - pTrack.GetAbsOrigin()).Length() < (self.GetAbsOrigin() - pNearest.GetAbsOrigin()).Length())
				@pNearest = pTrack;
		}

		@m_ppath = cast<CPathTrack@>(pNearest);

		if (self.GetSpeed() != 0)
		{
			NextThink(self.GetLastThink() + 0.1, false);
			SetThink(ThinkFunc(this.Next));
		}
	}

	void SetTrack(CPathTrack@ track) { @m_ppath = @track.Nearest(self.GetAbsOrigin()); }
	
	void SetControls(CBaseEntity@ pControls)
	{
		Vector offset = pControls.GetAbsOrigin() - self.GetOldOrigin();
		m_controlMins = pControls.GetRelMin() + offset;
		m_controlMaxs = pControls.GetRelMax() + offset;
	}

	bool OnControls(const CBaseEntity@ pTest) const
	{
		Vector offset = pTest.GetAbsOrigin() - self.GetAbsOrigin();

		/*
		if( self.GetSpawnFlags().Any( SF_TRACKTRAIN_NOCONTROL ) )
			return false;
		*/

		Math::MakeVectors(self.GetAbsAngles());
		
		Vector local;
		local.x = DotProduct(offset, Globals.v_forward);
		local.y = -DotProduct(offset, Globals.v_right);
		local.z = DotProduct(offset, Globals.v_up);

		if (local.x >= m_controlMins.x && local.y >= m_controlMins.y && local.z >= m_controlMins.z && local.x <= m_controlMaxs.x && local.y <= m_controlMaxs.y && local.z <= m_controlMaxs.z)
			return true;

		return false;
	}
	
	void StopSound()
	{
		if (m_soundPlaying != 0 && !self.GetNoise().isEmpty())
		{
			SoundSystem.StopSound(self, SoundChan::STATIC, self.GetNoise());
			if (m_sounds < 5)
				SoundSystem.EmitSoundDyn( self, SoundChan::ITEM, "plats/vehicle_brake1.wav", m_flVolume, Attn::NORM, 0, 100 );
		}

		m_soundPlaying = 0;
	}

	void UpdateSound()
	{
		if (self.GetNoise().isEmpty())
			return;

		float flpitch = VEHICLE_STARTPITCH + (abs(int(self.GetSpeed())) * (VEHICLE_MAXPITCH - VEHICLE_STARTPITCH) / VEHICLE_MAXSPEED);

		if (flpitch > 200)
			flpitch = 200;

		if (m_soundPlaying == 0)
		{
			if (m_sounds < 5)
				SoundSystem.EmitSoundDyn( self, SoundChan::ITEM, "plats/vehicle_brake1.wav", m_flVolume, Attn::NORM, 0, 100 );

			SoundSystem.EmitSoundDyn(self, SoundChan::STATIC, self.GetNoise(), m_flVolume, Attn::NORM, 0, int(flpitch));
			m_soundPlaying = 1;
		}
		else
		{
			SoundSystem.EmitSoundDyn(self, SoundChan::STATIC, self.GetNoise(), m_flVolume, Attn::NORM, SoundFlag::CHANGE_PITCH, int(flpitch));
		}
	}
	
	CBasePlayer@ GetDriver()
	{
		return m_pDriver;
	}
	
	void SetDriver( CBasePlayer@ pDriver )
	{
		@m_pDriver = @pDriver;

		if( pDriver !is null )
			SoundSystem.EmitSoundDyn( self, SoundChan::ITEM, "plats/vehicle_ignition.wav", 0.8, Attn::NORM, 0, Pitch::NORM );
	}

	CPathTrack@ m_ppath;
	float m_length;
	float m_width;
	float m_height;
	float m_speed;
	float m_dir;
	float m_startSpeed;
	Vector m_controlMins;
	Vector m_controlMaxs;
	int m_soundPlaying;
	int m_sounds;
	int m_acceleration;
	float m_flVolume;
	float m_flBank;
	float m_oldSpeed;
	int m_iTurnAngle;
	float m_flSteeringWheelDecay;
	float m_flAcceleratorDecay;
	float m_flTurnStartTime;
	float m_flLaunchTime;
	float m_flLastNormalZ;
	float m_flCanTurnNow;
	float m_flUpdateSound;
	Vector m_vFrontLeft;
	Vector m_vFront;
	Vector m_vFrontRight;
	Vector m_vBackLeft;
	Vector m_vBack;
	Vector m_vBackRight;
	Vector m_vSurfaceNormal;
	Vector m_vVehicleDirection;
	CBasePlayer@ m_pDriver;
}

const string VEHICLE_RC_EHANDLE_KEY = "VEHICLE_RC_EHANDLE_KEY"; //Key into player user data used to keep track of vehicle RC state

void TurnVehicleRCControlOff( CBasePlayer@ pPlayer )
{
	EHANDLE train = EHANDLE( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] );
				
	if( train )
	{
		func_vehicle_custom@ ptrain = func_vehicle_custom_Instance( train );
		
		if( ptrain !is null )
			ptrain.SetDriver( null );
	}
			
	pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] = EHANDLE();
							
	pPlayer.m_afPhysicsFlags &= ~PhysFlag::ONTRAIN;
	pPlayer.m_iTrain = TrainFlag::NEW|TrainFlag::OFF;
}

enum FuncVehicleControlsFlags
{
	SF_VEHICLE_RC = 1 << 0, //This func_vehiclecontrols is a remote control, not driver control
}

class func_vehiclecontrols : CCustomCBaseEntity
{
	int ObjectCaps()
	{
		return ( BaseClass.ObjectCaps() & ~FCAP_ACROSS_TRANSITION ) | 
		( self.GetSpawnFlags().Any( SF_VEHICLE_RC ) ? int( FCAP_IMPULSE_USE ) : 0 );
	}
	
	//Overridden because the default rules don't work correctly here
	bool IsBSPModel()
	{
		return true;
	}
	
	void Spawn()
	{
		if( self.GetSpawnFlags().Any( SF_VEHICLE_RC ) )
		{
			self.SetSolidType( SOLID_BSP );
			self.SetMoveType( MOVETYPE_PUSH );
		}
		else
		{
			self.SetSolidType( SOLID_NOT );
			self.SetMoveType( MOVETYPE_NONE );
		}
		
		self.SetModel( self.GetModelName() );
		
		self.SetSize( self.GetRelMin(), self.GetRelMax() );
		self.SetAbsOrigin( self.GetAbsOrigin() );

		SetThink( ThinkFunc( Find ) );
		self.SetNextThink( Globals.time );
	}
	
	void Find()
	{
		CBaseEntity@ pTarget = null;
		
		do
		{
			@pTarget = @Entity::FindEntityByTargetname( pTarget, self.GetTarget() );
		}
		while (pTarget !is null && !pTarget.ClassnameIs( "func_vehicle_custom" ) );
		
		func_vehicle_custom@ ptrain = null;

		if( pTarget !is null )
		{
			@ptrain = @func_vehicle_custom_Instance( pTarget );
			
			//Only set controls if this is a non-RC control
			if( ptrain !is null && !self.GetSpawnFlags().Any( SF_VEHICLE_RC ) )
				ptrain.SetControls( self );
		}
		else
			Engine.Alert( at_console, "No func_vehicle_custom %1\n", self.GetTarget() );

		if( !self.GetSpawnFlags().Any( SF_VEHICLE_RC ) || ptrain is null )
			Entity::Remove( self );
		else
			m_hVehicle = pTarget;
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( pActivator is null || !pActivator.IsPlayer() )
			return;
			
		if( !m_hVehicle )
		{
			Entity::Remove( self );
			return;
		}
			
		func_vehicle_custom@ ptrain = func_vehicle_custom_Instance( m_hVehicle );
		
		if( ptrain !is null )
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
		
			bool fisInControl = EHANDLE( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] );
			
			{
				CBasePlayer@ pDriver = ptrain.GetDriver();
				
				if( pDriver !is null )
				{
					TurnVehicleRCControlOff( pDriver );
					
					ptrain.SetDriver( null );
				}
			}
			
			if( !fisInControl )
			{
				pPlayer.m_afPhysicsFlags |= PhysFlag::ONTRAIN;
				pPlayer.m_iTrain = Player::TrainSpeed(int(ptrain.self.GetSpeed()), ptrain.self.GetImpulse());
				pPlayer.m_iTrain |= TrainFlag::NEW;
				
				CBaseEntity@ pDriver = ptrain.GetDriver();
				
				if( pDriver !is null )
				{
					CBasePlayer@ pPlayerDriver = cast<CBasePlayer@>( pDriver );
					
					if( pPlayerDriver !is null )
					{
						TurnVehicleRCControlOff( pPlayerDriver );
					}
				}
				
				ptrain.SetDriver( pPlayer );
				
				pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] = m_hVehicle;
			}
		}
		else
			Entity::Remove( self );
	}
	
	EHANDLE m_hVehicle;
}

func_vehicle_custom@ func_vehicle_custom_Instance( CBaseEntity@ pEntity )
{
	if(	pEntity.ClassnameIs( "func_vehicle_custom" ) )
		return cast<func_vehicle_custom@>( CustomEnts::Cast( pEntity ) );

	return null;
}

float Fix(float angle)
{
	while (angle < 0)
		angle += 360;
	while (angle > 360)
		angle -= 360;

	return angle;
}

Vector FixupAngles(Vector v)
{
	v.x = Fix(v.x);
	v.y = Fix(v.y);
	v.z = Fix(v.z);
	
	return v;
}

/*
*	Call this to init func_vehicle_custom
*	If you want debugging code accessible through chat, set bAddDebugCode to true
*/
void VehicleMapInit( bool bRegisterHooks, bool bAddDebugCode = false )
{
	if( bRegisterHooks )
	{
		if( bAddDebugCode )
		{
			Events::Player::Say.Hook( @VehicleClientSay );
		}
		
		Events::Player::Use.Hook( @VehiclePlayerUse );
		Events::Player::PreThink.Hook( @VehiclePlayerPreThink );
		Events::Player::ClientPutInServer.Hook( @VehicleClientPutInServer );
	}
	
	g_CustomEntities.RegisterCustomEntity( "func_vehicle_custom", "func_vehicle_custom" );
	g_CustomEntities.RegisterCustomEntity( "func_vehiclecontrols", "func_vehiclecontrols" );
	
	//Create beams between all func_vehicle_custom entities
	/*
	const string szSprite = "sprites/xbeam1.spr";
	
	g_engfuncs.PrecacheModel( szSprite );
	
	CBaseEntity@ pPrevEntity = null;
	CBaseEntity@ pEntity = null;
	
	array<EHANDLE>@ pBeams = array<EHANDLE>();
	
	while( ( @pEntity = Entity::FindEntityByClassname( pEntity, "func_vehicle_custom" ) ) !is null )
	{
		if( pPrevEntity !is null )
		{
			CBeam@ pBeam = Entity::CreateBeam( szSprite, 40 );
			
			pBeam.EntsInit( pPrevEntity, pEntity );
			pBeam.SetFlags( BEAM_FSINE );
			//pBeam.SetEndAttachment( 1 );
			//pBeam.GetSpawnFlags() |= SF_BEAM_TEMPORARY;
			
			pBeams.insertLast( EHANDLE( pBeam ) );
		}
		
		@pPrevEntity = @pEntity;
	}
	
	if( !pBeams.isEmpty() )
	{
		g_Scheduler.SetInterval( "UpdateBeams", 0.1, ( 1 / 0.1 ) * 60, pBeams );
		g_Scheduler.SetTimeout( "CleanupBeams", 60, pBeams );
	}
	*/
}

/*
void UpdateBeams( array<EHANDLE>@ pBeams )
{
	for( uint uiIndex = 0; uiIndex < pBeams.length(); ++uiIndex )
	{
		if( pBeams[ uiIndex ] )
		{
			cast<CBeam@>( pBeams[ uiIndex ] ).RelinkBeam();
		}
	}
}

void CleanupBeams( array<EHANDLE>@ pBeams )
{
	for( uint uiIndex = 0; uiIndex < pBeams.length(); ++uiIndex )
	{
		Entity::Remove( pBeams[ uiIndex ] );
	}
	
	pBeams.resize(0);
}
*/

HookReturnCode VehicleClientPutInServer( CBasePlayer@ pPlayer )
{
	dictionary@ userData = pPlayer.GetUserData();
	
	userData.set( VEHICLE_RC_EHANDLE_KEY, EHANDLE() );
	
	return HOOK_CONTINUE;
}

HookReturnCode VehiclePlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if ( ( pPlayer.m_afButtonPressed & InputFlag::USE ) != 0 )
	{
		if( EHANDLE( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] ) )
		{
			uiFlags |= UseFlag::SKIP_USE;
			
			TurnVehicleRCControlOff( pPlayer );
			
			return HOOK_CONTINUE;
		}
		
		if ( !pPlayer.m_hTank )
		{
			if ( ( pPlayer.m_afPhysicsFlags & PhysFlag::ONTRAIN ) != 0 )
			{
				pPlayer.m_afPhysicsFlags &= ~PhysFlag::ONTRAIN;
				pPlayer.m_iTrain = TrainFlag::NEW|TrainFlag::OFF;

				CBaseEntity@ pTrain = pPlayer.GetGroundEntity();

				//Stop driving this vehicle if +use again
				if( pTrain !is null )
				{
					func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
					
					if( pVehicle !is null )
						pVehicle.SetDriver( null );
				}

				uiFlags |= UseFlag::SKIP_USE;
				
				return HOOK_CONTINUE;
			}
			else
			{	// Start controlling the train!
				CBaseEntity@ pTrain = pPlayer.GetGroundEntity();
				
				if ( pTrain !is null && (pPlayer.GetButtons() & InputFlag::JUMP) == 0 && pPlayer.GetFlags().Any( FL_ONGROUND ) && (pTrain.ObjectCaps() & FCAP_DIRECTIONAL_USE) != 0 && pTrain.OnControls(pPlayer) )
				{
					pPlayer.m_afPhysicsFlags |= PhysFlag::ONTRAIN;
					pPlayer.m_iTrain = Player::TrainSpeed(int(pTrain.GetSpeed()), pTrain.GetImpulse().Get());
					pPlayer.m_iTrain |= TrainFlag::NEW;

					//Start driving this vehicle
					func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
						
					if( pVehicle !is null )
						pVehicle.SetDriver( pPlayer );
						
					uiFlags |= UseFlag::SKIP_USE;
					return HOOK_CONTINUE;
				}
			}
		}
	}
	
	return HOOK_CONTINUE;
}

//If player in air, disable control of train
bool HandlePlayerInAir( CBasePlayer@ pPlayer, CBaseEntity@ pTrain )
{
	if ( !pPlayer.GetFlags().Any( FL_ONGROUND ) )
	{
		// Turn off the train if you jump, strafe, or the train controls go dead
		pPlayer.m_afPhysicsFlags &= ~PhysFlag::ONTRAIN;
		pPlayer.m_iTrain = TrainFlag::NEW|TrainFlag::OFF;

		//Set driver to NULL if we stop driving the vehicle
		if( pTrain !is null )
		{
			func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
			
			if( pVehicle !is null )
				pVehicle.SetDriver( null );
		}
		
		if( EHANDLE( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] ) )
		{
			TurnVehicleRCControlOff( pPlayer );
		}
		
		return true;
	}
	
	return false;
}

HookReturnCode VehiclePlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	CBaseEntity@ pTrain = null;
	
	bool fUsingRC = EHANDLE( pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ] );
	
	if ( ( pPlayer.m_afPhysicsFlags & PhysFlag::ONTRAIN ) != 0 || fUsingRC )
	{
		pPlayer.GetFlags() |= FL_ONTRAIN;
	
		@pTrain = pPlayer.GetGroundEntity();
		
		if ( pTrain is null )
		{
			TraceResult trainTrace;
			// Maybe this is on the other side of a level transition
			Util::TraceLine( pPlayer.GetAbsOrigin(), pPlayer.GetAbsOrigin() + Vector(0,0,-38), IgnoreMonsters::IGNORE_MONSTERS, pPlayer, trainTrace );

			// HACKHACK - Just look for the func_tracktrain classname
			if ( trainTrace.flFraction != 1.0 && trainTrace.pHit !is null )
				@pTrain = trainTrace.pHit;

			if ( pTrain is null || (pTrain.ObjectCaps() & FCAP_DIRECTIONAL_USE) == 0 || !pTrain.OnControls(pPlayer) )
			{
				//ALERT( at_error, "In train mode with no train!\n" );
				pPlayer.m_afPhysicsFlags &= ~PhysFlag::ONTRAIN;
				pPlayer.m_iTrain = TrainFlag::NEW|TrainFlag::OFF;

				//Set driver to NULL if we stop driving the vehicle
				if( pTrain !is null )
				{
					func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
					
					if( pVehicle !is null )
						pVehicle.SetDriver( null );
				}
				
				uiFlags |= PreThinkFlag::SKIP_VEHICLES;
				return HOOK_CONTINUE;
			}
		}
		else if ( HandlePlayerInAir( pPlayer, pTrain ) )
		{
			uiFlags |= PreThinkFlag::SKIP_VEHICLES;
			return HOOK_CONTINUE;
		}

		float vel = 0;

		//Check if it's a func_vehicle - Solokiller 2014-10-24
		if( fUsingRC )
		{
			@pTrain = EHANDLE(pPlayer.GetUserData()[ VEHICLE_RC_EHANDLE_KEY ]);
			
			//fContinue = false;
		}
		
		if( pTrain is null )
			return HOOK_CONTINUE;
			
		func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
		
		if( pVehicle is null )
			return HOOK_CONTINUE;
			
		int buttons = pPlayer.GetButtons().Get();
		
		if( ( buttons & InputFlag::FORWARD ) != 0 )
		{
			vel = 1;
			pTrain.Use( pPlayer, pPlayer, USE_SET, vel );
		}

		if( ( buttons & InputFlag::BACK ) != 0 )
		{
			vel = -1;
			pTrain.Use( pPlayer, pPlayer, USE_SET, vel );
		}

		if( ( buttons & InputFlag::MOVELEFT ) != 0 )
		{
			vel = 20;
			pTrain.Use( pPlayer, pPlayer, USE_SET, vel );
		}

		if( ( buttons & InputFlag::MOVERIGHT ) != 0 )
		{
			vel = 30;
			pTrain.Use( pPlayer, pPlayer, USE_SET, vel );
		}

		if (vel != 0)
		{
			pPlayer.m_iTrain = Player::TrainSpeed(int(pTrain.GetSpeed()), pTrain.GetImpulse().Get());
			pPlayer.m_iTrain |= TrainFlag::ACTIVE|TrainFlag::NEW;
		}
		
		uiFlags |= PreThinkFlag::SKIP_VEHICLES;
	}
	else 
		pPlayer.GetFlags() &= int( ~FL_ONTRAIN );
	
	return HOOK_CONTINUE;
}

HookReturnCode VehicleClientSay( CSayArgs@ args )
{
	const CCommand@ pArguments = args.GetArguments();
	
	bool fHandled = false;
	
	if( pArguments.ArgC() >= 3 )
	{
		CBaseEntity@ pTrain = Entity::FindEntityByTargetname( null, pArguments[ 1 ] );
			
		if( pTrain !is null )
		{
			func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
			
			if( pVehicle !is null )
			{
				float flNewValue = atof( pArguments[ 2 ] );

				if( pArguments[ 0 ] == "vehicle_speed" )
				{
					pVehicle.m_speed = flNewValue;
					Engine.Alert( at_console, "changing speed to %1\n", flNewValue );
					
					fHandled = true;
				}
				else if( pArguments[ 0 ] == "vehicle_accel" )
				{
					pVehicle.m_acceleration = int(flNewValue);
					Engine.Alert( at_console, "changing acceleration to %1\n", flNewValue );
					
					fHandled = true;
				}
			}
		}
	}
	else if( pArguments.ArgC() >= 2 )
	{
		CBaseEntity@ pTrain = Entity::FindEntityByTargetname( null, pArguments[ 1 ] );
			
		if( pTrain !is null )
		{
			func_vehicle_custom@ pVehicle = cast<func_vehicle_custom@>( CustomEnts::Cast( pTrain ) );
			
			if( pVehicle !is null )
			{
				if( pArguments[ 0 ] == "vehicle_restart" )
				{
					pVehicle.Restart();
					Engine.Alert( at_console, "restarting vehicle\n" );
					
					fHandled = true;
				}
			}
		}
	}
	
	if( !fHandled )
		Engine.Alert( at_console, "not changing anything\n" );

	return HOOK_CONTINUE;
}