#if SERVER_DLL
#include "func_vehicle_custom"

void MapInit()
{
	VehicleMapInit( true, true );
}
#endif

#if CLIENT_DLL
void MapInit()
{
}
#endif