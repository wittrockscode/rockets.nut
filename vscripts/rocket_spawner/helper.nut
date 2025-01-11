::HookCustomThink <-  function(hEntity, hTarget, hSpeed, strThinkFunc, funcCallback, fDelay = 0.1)
{
	if ((hEntity.GetScriptThinkFunc() != "") && (hEntity.GetScriptThinkFunc() != "CustomThink_"+strThinkFunc))
	{
		printl("Another think hook is active");

		return;
	}

	local hEntityScope = hEntity.GetScriptScope();

	if (!("ThinkHooks" in hEntityScope)) hEntityScope.ThinkHooks <- [];

	if (hEntityScope.ThinkHooks.find(funcCallback) != null) { printl("Think callback already added"); return; }

	hEntityScope.ThinkHooks.append(funcCallback);

	if (!("CustomThink_"+strThinkFunc in hEntityScope)) hEntityScope["CustomThink_"+strThinkFunc] <- function()
	{
		foreach (iIndex, funcThinkCb in this.ThinkHooks)
		{
			funcThinkCb(hTarget, hSpeed);
		}

		return fDelay;
	}

	AddThinkToEnt(hEntity, "CustomThink_"+strThinkFunc);
}

::IsPlayerAlive <- function(client)
{
	return NetProps.GetPropInt(client, "m_lifeState") == 0;
}

function setup() {
  PrecacheModel("models/weapons/w_models/w_rocket.mdl")
  PrecacheEntityFromTable({
    classname = "info_particle_system",
    start_active = false,
    effect_name = "eyeboss_projectile"
  })

  PrecacheEntityFromTable({
    classname = "env_explosion",
    spawnflags = 2,
    rendermode = 5
  });

  printl("Precache complete")
}

::IsValidClient <- function(client)
{
	try
	{
		return client != null && client.IsValid() && client.IsPlayer() && IsPlayerAlive(client);
	}
	catch(e)
	{
		return false;
	}
}

::CalculateDirectionToPosition <- function(rocket_entity, position)
{
  local vTemp = position - rocket_entity.GetOrigin();
  vTemp.Norm();

  return vTemp;
}

::LerpVectors <- function(vA, vB, t)
{
	(t < 0.0) ? 0.0 : (t > 1.0) ? 1.0 : t;

	return vA + (vB - vA) * t;
}

::RangePercentage <- function(a, b, t)
{
  return ((t - a) * 100) / (b - a);
}

::RangeValue <- function(a, b, t)
{
  return (t * (b - a) / 100) + a;
}

::ClampValue <- function(value, min, max)
{
  return (value < min) ? min : (value > max) ? max : value;
}

::NormalizeVector <- function(vector)
{
  local length = vector.Length()
  if (length == 0.0) return vector
  return Vector(vector.x / length, vector.y / length, vector.z / length)
}

// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Creating_Bots_That_Use_the_Navmesh
::VectorAngles <- function(forward)
{
	local yaw, pitch
	if ( forward.y == 0.0 && forward.x == 0.0 )
	{
		yaw = 0.0
		if (forward.z > 0.0)
			pitch = 270.0
		else
			pitch = 90.0
	}
	else
	{
		yaw = (atan2(forward.y, forward.x) * 180.0 / Constants.Math.Pi)
		if (yaw < 0.0)
			yaw += 360.0
		pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / Constants.Math.Pi)
		if (pitch < 0.0)
			pitch += 360.0
	}

	return QAngle(pitch, yaw, 0.0)
}
