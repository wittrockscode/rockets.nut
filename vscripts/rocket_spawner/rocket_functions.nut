function ROCKETS::DefaultRocketThink(rocket) {
  local rocket_entity = rocket.Entity;

  rocket_entity.SetForwardVector(ROCKETS.Helpers.NormalizeVector(rocket_entity.GetAbsVelocity()));
}

function ROCKETS::HomingRocketThink(rocket) {
  if (rocket == null) return;

  local rocket_entity = rocket.Entity;
  local target = rocket.Target;
  local speed = rocket.BaseSpeed;
  local follow_speed_multiplier = rocket.FollowSpeedMultiplier;
  local collision_avoidance = rocket.CollisionAvoidance;
  local target_prediction = rocket.TargetPrediction;

  if (!target.IsValid()) {
    rocket_entity.Kill();
    return;
  } else {
    local current_dir = rocket_entity.GetForwardVector();
    local center = target.GetCenter();
    local bounds = target.GetBoundingMaxs();
    local targetPosBase = Vector(center.x, center.y, center.z - (bounds.z / 2));
    local targetDistance = (targetPosBase - rocket_entity.GetOrigin()).Length();
    local targetHeading = ROCKETS.Helpers.NormalizeVector(target.GetAbsVelocity());
    local targetSpeed = target.GetAbsVelocity().Length();
    local speedDiff = targetSpeed - speed;

    if (follow_speed_multiplier > 1.0 && speedDiff > 0) {
      local followSpeed = targetSpeed * follow_speed_multiplier;

      if (speed < followSpeed) speed = followSpeed;
    }

    local targetPos = targetPosBase;
    local dontCheckFloor = false;

    if (target_prediction) {
      local timeToImpact = targetDistance / speed;
      local targetPosBase_prediction = targetPosBase + targetHeading.Scale(targetSpeed * timeToImpact);
      local z_offset_distance = bounds.z;

      local trace_output = {
        start = targetPosBase,
        end = targetPosBase - Vector(0.0, 0.0, 1.0) * z_offset_distance,
        mask = 100679691,
        ignore = target
      };
      TraceLineEx(trace_output);

      dontCheckFloor = trace_output.hit;

      if (trace_output.hit) z_offset_distance = trace_output.fraction * z_offset_distance;

      local preferredTargetPosLow = Vector(targetPosBase_prediction.x, targetPosBase_prediction.y, targetPosBase_prediction.z - z_offset_distance);
      local preferredTargetPosHigh = Vector(targetPosBase_prediction.x, targetPosBase_prediction.y, targetPosBase_prediction.z - (z_offset_distance / 2));

      if (((targetPosBase.z < rocket_entity.GetOrigin().z) || (targetDistance > z_offset_distance * 2)) && rocket_entity.GetOrigin().z < preferredTargetPosLow.z) {
        targetPosBase_prediction = preferredTargetPosLow;
      } else if ((targetDistance > z_offset_distance) && rocket_entity.GetOrigin().z < preferredTargetPosHigh.z) {
        targetPosBase_prediction = preferredTargetPosHigh;
      } else if (targetDistance < z_offset_distance / 2) {
        targetPosBase_prediction = targetPosBase;
      }

      targetPos = targetPosBase_prediction;
    }

    local percentage = ROCKETS.Helpers.ClampValue(
      ROCKETS.Helpers.RangePercentage(ROCKETS.Globals.MAX_TURNRATE_DISTANCE, ROCKETS.Globals.MIN_TURNRATE_DISTANCE, targetDistance),
      0,
      100
    );
    local turnrate = ROCKETS.Helpers.RangeValue(ROCKETS.Globals.MAX_TURNRATE, ROCKETS.Globals.MIN_TURNRATE, percentage);
    local target_direction = ROCKETS.Helpers.CalculateDirectionToPosition(rocket_entity, targetPos);
    local final_direction = ROCKETS.Helpers.LerpVectors(current_dir, target_direction, turnrate);

    if (collision_avoidance) {
      final_direction = ROCKETS.RocketCollision(rocket_entity, final_direction, dontCheckFloor, targetDistance);
    }

    rocket_entity.SetAbsVelocity(final_direction.Scale(speed));
    rocket_entity.SetForwardVector(final_direction);
  }
}

function ROCKETS::RocketCollision(rocket_entity, current_direction, dont_check_floor, targetDistance) {
  rocket_entity.ValidateScriptScope();
  local scope = rocket_entity.GetScriptScope();
  local current_dir = rocket_entity.GetForwardVector();
  if (!("last_normal" in scope)) scope["last_normal"] <- null;

  local trace_output = {
    start = rocket_entity.GetOrigin(),
    end = rocket_entity.GetOrigin() + current_dir * 200,
    mask = 67125259,
    ignore = rocket_entity
  };
  TraceLineEx(trace_output);

  if(trace_output.hit) {
    local normal = trace_output.plane_normal;
    if (dont_check_floor && normal.z > 0.5) return current_direction;

    if (targetDistance < (trace_output.endpos - rocket_entity.GetOrigin()).Length()) return current_direction;

    scope.last_normal = normal;

    local percentage = trace_output.fraction * 100;
    local turnrate = ROCKETS.Helpers.RangeValue(ROCKETS.Globals.MAX_TURNRATE, ROCKETS.Globals.MIN_TURNRATE, percentage);
    local target_direction = ROCKETS.Helpers.NormalizeVector(current_dir + normal);

    return ROCKETS.Helpers.LerpVectors(current_dir, target_direction, turnrate);
  } else {
    if (scope.last_normal != null) {
      local last_normal_inverted = scope.last_normal * -1;

      local trace_output2 = {
        start = rocket_entity.GetOrigin(),
        end = rocket_entity.GetOrigin() + last_normal_inverted * 90,
        mask = 67125259,
        ignore = rocket_entity
      };
      TraceLineEx(trace_output2);

      if (!trace_output2.hit) {
        scope.last_normal = null
        return current_direction;
      } else {
        return current_dir;
      }
    } else {
      return current_direction;
    }
  }
}

function ROCKETS::CreateExplosion(rocket_entity, rocket) {
  local explosion_entity = ROCKETS.CreateExplosionEntity();

  explosion_entity.Teleport(
    true, rocket_entity.GetOrigin(),
    false, QAngle(),
    false, Vector()
  );

  explosion_entity.AcceptInput("Explode", "", rocket_entity, rocket_entity);
  explosion_entity.Kill();

  ROCKETS.CreateImpulse(rocket_entity, rocket);
}

function ROCKETS::CreateExplosionEntity() {
  local explosion_entity = SpawnEntityFromTable("env_explosion", {
    spawnflags = 2,
    rendermode = 5
  });
  if (explosion_entity == null) return;

  NetProps.SetPropInt(explosion_entity, "m_iMagnitude", ROCKETS.Globals.ROCKET_DAMAGE);
  NetProps.SetPropFloat(explosion_entity, "m_flDamageForce", 0);
  NetProps.SetPropInt(explosion_entity, "m_iRadiusOverride", 100);

  return explosion_entity;
}

function ROCKETS::CreateImpulse(rocket_entity, rocket)
{
  local damage = rocket.Damage;
  local explosion_position = rocket_entity.GetOrigin() + Vector(0, 0, -50);

  if (rocket.Damage <= 0) return;

  if (rocket.DamageEveryone) {
    for (local i = 1; i <= MaxClients().tointeger(); i++) {
      player = PlayerInstanceFromIndex(i);
      if (player == null) continue;

      ROCKETS.ApplyEntityImpulse(player, explosion_position, damage);
    }
  } else {
    local target = rocket.Target;
    if (target == null) return;

    ROCKETS.ApplyEntityImpulse(target, explosion_position, damage)
  }
}

function ROCKETS::ApplyEntityImpulse(entity, impulse_origin, magnitude) {
	local impulse_strength = 0.0;
	local impulse_direction = null;
  local entity_position = entity.GetOrigin();
  local distance_to_explosion = (impulse_origin - entity_position).Length();
  if (distance_to_explosion >= magnitude) return;

  impulse_direction = entity_position - impulse_origin;
  impulse_direction.Norm();

  if (impulse_direction.z < 0.4) {
    impulse_direction.z = 0.4;
    impulse_direction.Norm();
  }

  if (distance_to_explosion < (magnitude / 2)) impulse_strength = magnitude * 3;
  else impulse_strength = (1.0 - ((2 * distance_to_explosion - magnitude) / magnitude)) * magnitude * 3;

  entity.ApplyAbsVelocityImpulse(impulse_direction * impulse_strength);
}
