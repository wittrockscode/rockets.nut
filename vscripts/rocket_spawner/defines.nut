::ROCKETS <- {};
ROCKETS.Helpers <- {};
ROCKETS.Globals <- {
  ROCKET_DAMAGE                   = 90.0,
  ROCKET_SPEED                    = 1100.0,
  ROCKET_COLLISION_AVOIDANCE      = true,
  ROCKET_TARGET_PREDICTION        = true,
  PARTICLE_SYSTEM_NAME            = "critical_rocket_blue",
  ROCKET_BOUNDS_P                 = Vector(18.3205, 3.417, 3.417),
  ROCKET_FOLLOW_SPEED_MULTIPLIER  = 2,
  ROCKET_EXPLODE                  = true,
  ROCKET_SCALE                    = 1.0,
  MAX_TURNRATE                    = 0.7,
  MIN_TURNRATE                    = 0.23,
  MAX_TURNRATE_DISTANCE           = 50,
  MIN_TURNRATE_DISTANCE           = 400,
  ROCKET_ONLY_DAMAGE_TARGET       = true,
  ROCKET_HOMING                   = false,
  ROCKET_TARGET                   = null,
  ROCKET_LIMIT                    = -1,
};
ROCKETS.RocketArgs <- {
  position                = null,
  direction               = null,
  speed                   = ROCKETS.Globals.ROCKET_SPEED,
  damage                  = ROCKETS.Globals.ROCKET_DAMAGE,
  explode                 = ROCKETS.Globals.ROCKET_EXPLODE,
  target                  = ROCKETS.Globals.ROCKET_TARGET,
  scale                   = ROCKETS.Globals.ROCKET_SCALE,
  follow_speed_multiplier = ROCKETS.Globals.ROCKET_FOLLOW_SPEED_MULTIPLIER,
  collision_avoidance     = ROCKETS.Globals.ROCKET_COLLISION_AVOIDANCE,
  target_prediction       = ROCKETS.Globals.ROCKET_TARGET_PREDICTION,
  limit                   = ROCKETS.Globals.ROCKET_LIMIT,
  homing                  = ROCKETS.Globals.ROCKET_HOMING,
  damage_everyone         = !ROCKETS.Globals.ROCKET_ONLY_DAMAGE_TARGET,
};

IncludeScript("rocket_spawner/helper.nut");
IncludeScript("rocket_spawner/rocket_functions.nut");
IncludeScript("rocket_spawner/class.nut");
