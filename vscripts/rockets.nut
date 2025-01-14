IncludeScript("rocket_spawner/defines.nut");

function ReplaceRocket(args_table = {}) {
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

function SpawnRocketAtEntity(spawn_point_name, args_table = {}) {
  local spawn_point = Entities.FindByName(null, spawn_point_name);
  if (spawn_point == null) return;

  local args = ROCKETS.Helpers.PopulateArgs(args_table);

  args.target = args.target == null ? activator : Entities.FindByName(null, args.target);
  if (args.target == null) return;

  if (args.limit > 0 && activator.ValidateScriptScope()) {
    local scope = activator.GetScriptScope();

    if (!("rockets_limit" in scope)) scope["rockets_limit"] <- {};
    if (!(spawn_point_name in scope.rockets_limit)) scope.rockets_limit[spawn_point_name] <- 1;
    else scope.rockets_limit[spawn_point_name] += 1;

    if (scope.rockets_limit[spawn_point_name] > args.limit) return;
  }

  args.position = spawn_point.GetOrigin();
  args.direction = spawn_point.GetAbsAngles();

  ROCKETS.SpawnedRocket(args);
}

function ResetLimit(limit_entity_name) {
  local scope = activator.GetScriptScope();
  if (!("rockets_limit" in scope)) return;

  if (limit_entity_name in scope.rockets_limit) {
    scope.rockets_limit[limit_entity_name] = 0;
  }
}

function ResetLimits() {
  local scope = activator.GetScriptScope();
  if (!("rockets_limit" in scope)) return;

  scope.rockets_limit <- {};
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
  PrecacheModel("models/weapons/w_models/w_rocket.mdl");
  PrecacheEntityFromTable({
    classname = "info_particle_system",
    start_active = false,
    effect_name = ROCKETS.Globals.PARTICLE_SYSTEM_NAME
  });
  PrecacheEntityFromTable({
    classname = "env_explosion",
    spawnflags = 2,
    rendermode = 5
  });
}

function OnGameEvent_player_spawn(params) {
  if ("team" in params && params.team == 0 && "userid" in params) {
    local player = GetPlayerFromUserID(params.userid);
    player.ValidateScriptScope();
  }
}
