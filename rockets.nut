IncludeScript("rocket_spawner/class.nut");
IncludeScript("rocket_spawner/rocket_functions.nut");
IncludeScript("rocket_spawner/helper.nut");

::ROCKET_SPAWNER <- {};

::GLOBAL_ATTRS <- {
  ROCKET_DAMAGE = 90.0,
  ROCKET_SPEED = 1100
};

::ReplaceRocketHoming <- function(speed = null, damage = null)
{
  local player_rocket = activator;

  if (player_rocket == null) return;

  local player_rocket_velocity = player_rocket.GetAbsVelocity() + player_rocket.GetBaseVelocity();
  local player_rocket_angles = VectorAngles(player_rocket_velocity);
  local player_rocket_speed = player_rocket_velocity.Length();

  local target = player_rocket.GetOwner();
  if (target == null) return;

  SpawnedRocket(player_rocket.GetOrigin(), player_rocket_angles, speed ? speed : player_rocket_speed, damage, true, target);

  player_rocket.Kill();
}

::ReplaceRocket <-  function(speed = null, damage = null)
{
  local player_rocket = activator;

  if (player_rocket == null) return;

  local player_rocket_velocity = player_rocket.GetAbsVelocity() + player_rocket.GetBaseVelocity();
  local player_rocket_angles = VectorAngles(player_rocket_velocity);
  local player_rocket_speed = player_rocket_velocity.Length();

  SpawnedRocket(player_rocket.GetOrigin(), player_rocket_angles, speed ? speed : player_rocket_speed, damage, true);

  player_rocket.Kill();
}

::SpawnRocketAtEntityHoming <-  function(spawn_point_name, speed = null)
{
  local target = activator;

  if (target == null) return;

  local spawn_point = Entities.FindByName(null, spawn_point_name);
  local position = spawn_point.GetOrigin();
  local angles = spawn_point.GetAbsAngles();

  SpawnedRocket(position, angles, speed, null, true, target);
}

::SpawnRocketAtEntity <-  function(spawn_point_name, speed_ = null)
{
  local spawn_point = Entities.FindByName(null, spawn_point_name);
  local position = spawn_point.GetOrigin();
  local angles = spawn_point.GetAbsAngles();

  SpawnedRocket(position, angles, speed_, null, true);
}

::SetAttribute <- function(argument = null)
{
  if (argument == null)
  {
    activator.AcceptInput("Disable", "", activator, activator);
    printl("All attributes set");
    return;
  }

  local key_value = split(argument, "=");
  if (key_value.len() != 2) return;

  local key = key_value[0];
  local value = key_value[1];

  switch(key)
	{
		case "rocket_damage" :
			GLOBAL_ATTRS.ROCKET_DAMAGE <- value.tofloat();
			break;
		case "rocket_speed" :
			GLOBAL_ATTRS.ROCKET_SPEED <- value.tofloat();
			break;
    default:
      return;
	}

  printl("Set " + key + " to " + value);
}

setup()

DeepPrintTable(SpawnedRocket)
