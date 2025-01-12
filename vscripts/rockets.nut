::ROCKETS <- {
  HELPERS = {},
  GLOBAL_ATTRS = {
    ROCKET_DAMAGE = 90.0,
    ROCKET_SPEED = 1100,
    PARTICLE_SYSTEM_NAME = "critical_rocket_blue",
    ROCKET_BOUNDS_P = Vector(18.3205, 3.417, 3.417),
    ROCKET_FOLLOW_SPEED_MULTIPLIER = 1.5,
    MAX_TURNRATE = 0.7,
    MIN_TURNRATE = 0.23,
    MAX_TURNRATE_DISTANCE = 50,
    MIN_TURNRATE_DISTANCE = 400
  }
};

IncludeScript("rocket_spawner/class.nut");
IncludeScript("rocket_spawner/rocket_functions.nut");
IncludeScript("rocket_spawner/helper.nut");

function ReplaceRocketHoming(
  target_entity_name = null,
  speed = null,
  damage = null,
  scale = 1.0,
  follow_speed = ROCKETS.GLOBAL_ATTRS.ROCKET_FOLLOW_SPEED_MULTIPLIER
){
  local player_rocket = activator;

  if (player_rocket == null) return;

  local player_rocket_velocity = player_rocket.GetAbsVelocity() + player_rocket.GetBaseVelocity();
  local player_rocket_angles = ROCKETS.HELPERS.VectorAngles(player_rocket_velocity);
  local player_rocket_speed = player_rocket_velocity.Length();

  local target_entity = target_entity_name == null ? player_rocket.GetOwner() : Entities.FindByName(null, target_entity_name);

  if (target_entity == null) return;

  ROCKETS.SpawnedRocket(
    player_rocket.GetOrigin(),
    player_rocket_angles,
    speed ? speed : player_rocket_speed,
    damage,
    true,
    target_entity,
    scale,
    follow_speed
  );

  player_rocket.Kill();
}

function ReplaceRocket(
  speed = null,
  damage = null,
  scale = 1.0,
  follow_speed = ROCKETS.GLOBAL_ATTRS.ROCKET_FOLLOW_SPEED_MULTIPLIER
){
  local player_rocket = activator;

  if (player_rocket == null) return;

  local player_rocket_velocity = player_rocket.GetAbsVelocity() + player_rocket.GetBaseVelocity();
  local player_rocket_angles = ROCKETS.HELPERS.VectorAngles(player_rocket_velocity);
  local player_rocket_speed = player_rocket_velocity.Length();

  ROCKETS.SpawnedRocket(
    player_rocket.GetOrigin(),
    player_rocket_angles,
    speed ? speed : player_rocket_speed,
    damage,
    true,
    null,
    scale,
    follow_speed
  );

  player_rocket.Kill();
}

function SpawnRocketAtEntityHoming(
  spawn_point_name,
  target_entity_name = null,
  speed = null,
  damage = null,
  scale = 1.0,
  follow_speed = ROCKETS.GLOBAL_ATTRS.ROCKET_FOLLOW_SPEED_MULTIPLIER
){
  local target = target_entity_name == null ? activator : Entities.FindByName(null, target_entity_name);

  if (target == null) return;

  local spawn_point = Entities.FindByName(null, spawn_point_name);
  local position = spawn_point.GetOrigin();
  local angles = spawn_point.GetAbsAngles();

  ROCKETS.SpawnedRocket(
    position,
    angles,
    speed,
    damage,
    true,
    target,
    scale,
    follow_speed
  );
}

function SpawnRocketAtEntity(
  spawn_point_name,
  speed = null,
  damage = null,
  scale = 1.0,
  follow_speed = ROCKETS.GLOBAL_ATTRS.ROCKET_FOLLOW_SPEED_MULTIPLIER
){
  local spawn_point = Entities.FindByName(null, spawn_point_name);
  local position = spawn_point.GetOrigin();
  local angles = spawn_point.GetAbsAngles();

  ROCKETS.SpawnedRocket(
    position,
    angles,
    speed,
    damage,
    true,
    null,
    scale,
    follow_speed
  );
}

function SetAttribute(argument = null)
{
  if (argument == null)
  {
    activator.AcceptInput("Disable", "", activator, activator);
    printl("All attributes set");
    return;
  }

  local argument_uppercase = argument.toupper();

  local key_value = split(argument_uppercase, "=");
  if (key_value.len() != 2) return;

  local key = key_value[0];
  local value = key_value[1];

  if (ROCKETS.GLOBAL_ATTRS[key] == null) return;

  ROCKETS.GLOBAL_ATTRS[key] = value;

  printl("Set " + key + " to " + value);
}

function Precache()
{
  PrecacheModel("models/weapons/w_models/w_rocket.mdl")
  PrecacheEntityFromTable({
    classname = "info_particle_system",
    start_active = false,
    effect_name = ROCKETS.GLOBAL_ATTRS.PARTICLE_SYSTEM_NAME
  })

  PrecacheEntityFromTable({
    classname = "env_explosion",
    spawnflags = 2,
    rendermode = 5
  });
}
