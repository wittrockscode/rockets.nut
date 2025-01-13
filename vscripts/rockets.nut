::ROCKETS <- {};
ROCKETS.Helpers <- {};
ROCKETS.Globals <- {
  ROCKET_DAMAGE                   = 90.0,
  ROCKET_SPEED                    = 1100.0,
  ROCKET_COLLISION_AVOIDANCE      = true,
  PARTICLE_SYSTEM_NAME            = "critical_rocket_blue",
  ROCKET_BOUNDS_P                 = Vector(18.3205, 3.417, 3.417),
  ROCKET_FOLLOW_SPEED_MULTIPLIER  = 2,
  ROCKET_EXPLODE                  = true,
  ROCKET_MODEL_SCALE              = 1.0,
  MAX_TURNRATE                    = 0.7,
  MIN_TURNRATE                    = 0.23,
  MAX_TURNRATE_DISTANCE           = 50,
  MIN_TURNRATE_DISTANCE           = 400,
};
ROCKETS.RocketArgs <- {
  position                = null,
  direction               = null,
  speed                   = null,
  damage                  = null,
  explode                 = null,
  target                  = null,
  scale                   = null,
  follow_speed_multiplier = null,
  collision_avoidance     = null,
};

IncludeScript("rocket_spawner/class.nut");
IncludeScript("rocket_spawner/rocket_functions.nut");
IncludeScript("rocket_spawner/helper.nut");

function ReplaceRocketHoming(args_table = {}) {
  local args = ROCKETS.Helpers.PopulateArgs(args_table);

  local player_rocket = activator;
  if (player_rocket == null) return;

  local player_rocket_velocity = player_rocket.GetAbsVelocity() + player_rocket.GetBaseVelocity();
  local player_rocket_angles = ROCKETS.Helpers.VectorAngles(player_rocket_velocity);
  local player_rocket_speed = player_rocket_velocity.Length();

  args.target = args.target == null ? player_rocket.GetOwner() : Entities.FindByName(null, args.target);
  if (args.target == null) return;

  args.position = player_rocket.GetOrigin();
  args.direction = player_rocket_angles;
  args.speed = args.speed ? args.speed : player_rocket_speed;

  ROCKETS.SpawnedRocket(args);

  player_rocket.Kill();
}

function ReplaceRocket(args_table = {}) {
  local args = ROCKETS.Helpers.PopulateArgs(args_table);

  local player_rocket = activator;
  if (player_rocket == null) return;

  local player_rocket_velocity = player_rocket.GetAbsVelocity() + player_rocket.GetBaseVelocity();
  local player_rocket_angles = ROCKETS.Helpers.VectorAngles(player_rocket_velocity);
  local player_rocket_speed = player_rocket_velocity.Length();

  args.position = player_rocket.GetOrigin();
  args.direction = player_rocket_angles;
  args.speed = args.speed ? args.speed : player_rocket_speed;
  args.target = null;

  ROCKETS.SpawnedRocket(args);

  player_rocket.Kill();
}

function SpawnRocketAtEntityHoming(spawn_point_name, args_table = {}) {
  local args = ROCKETS.Helpers.PopulateArgs(args_table);

  args.target = args.target == null ? activator : Entities.FindByName(null, args.target);
  if (args.target == null) return;

  local spawn_point = Entities.FindByName(null, spawn_point_name);
  local position = spawn_point.GetOrigin();
  local angles = spawn_point.GetAbsAngles();

  args.position = position;
  args.direction = angles;

  ROCKETS.SpawnedRocket(args);
}

function SpawnRocketAtEntity(spawn_point_name, args_table = {}) {
  local spawn_point = Entities.FindByName(null, spawn_point_name);
  local position = spawn_point.GetOrigin();
  local angles = spawn_point.GetAbsAngles();

  local args = ROCKETS.Helpers.PopulateArgs(args_table);
  args.position = position;
  args.direction = angles;
  args.target = null;

  ROCKETS.SpawnedRocket(args);
}

function SetAttributes(args_table = {}) {
  foreach (key, value in args_table) {
    local key = key.toupper();
    if (key in ROCKETS.Globals) {
      ROCKETS.Globals[key] = value;
      printl(key + " set to " + value);
    }
  }

  activator.AcceptInput("Disable", "", activator, activator);
  printl("All attributes set");
}

function Precache() {
  PrecacheModel("models/weapons/w_models/w_rocket.mdl")
  PrecacheEntityFromTable({
    classname = "info_particle_system",
    start_active = false,
    effect_name = ROCKETS.Globals.PARTICLE_SYSTEM_NAME
  })
  PrecacheEntityFromTable({
    classname = "env_explosion",
    spawnflags = 2,
    rendermode = 5
  });
}
