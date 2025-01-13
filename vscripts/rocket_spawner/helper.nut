function ROCKETS::HELPERS::AddThinkFunc(entity, rocket, name, func, delay = 0.1) {
  local entityScope = entity.GetScriptScope();

  if (!("ThinkClbs" in entityScope)) entityScope.ThinkClbs <- [];

  entityScope.ThinkClbs.append(func);
  entityScope["ThinkFuncs_"+name] <- function() {
    foreach (func in this.ThinkClbs) {
      func(rocket);
    }
    return delay;
	}

	AddThinkToEnt(entity, "ThinkFuncs_"+name);
}

function ROCKETS::HELPERS::IsPlayerAlive(client) {
	return NetProps.GetPropInt(client, "m_lifeState") == 0;
}

function ROCKETS::HELPERS::IsValidClient(client) {
	try {
		return client != null && client.IsValid() && client.IsPlayer() && IsPlayerAlive(client);
	} catch(e) {
		return false;
	}
}

function ROCKETS::HELPERS::CalculateDirectionToPosition(rocket_entity, position) {
  local vTemp = position - rocket_entity.GetOrigin();
  vTemp.Norm();

  return vTemp;
}

function ROCKETS::HELPERS::LerpVectors(vA, vB, t) {
	t = (t < 0.0) ? 0.0 : (t > 1.0) ? 1.0 : t;

	return vA + (vB - vA) * t;
}

function ROCKETS::HELPERS::RangePercentage(a, b, t) {
  return ((t - a) * 100) / (b - a);
}

function ROCKETS::HELPERS::RangeValue(a, b, t) {
  return (t * (b - a) / 100) + a;
}

function ROCKETS::HELPERS::ClampValue(value, min, max) {
  return (value < min) ? min : (value > max) ? max : value;
}

function ROCKETS::HELPERS::NormalizeVector(vector) {
  local length = vector.Length();
  if (length == 0.0) return vector;
  return Vector(vector.x / length, vector.y / length, vector.z / length);
}

// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Creating_Bots_That_Use_the_Navmesh
function ROCKETS::HELPERS::VectorAngles(forward) {
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
