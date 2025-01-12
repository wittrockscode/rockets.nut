function ROCKETS::DefaultRocketThink(args)
{
  local rocket_entity = args[0];

  rocket_entity.SetForwardVector(ROCKETS.HELPERS.NormalizeVector(rocket_entity.GetAbsVelocity()));
}

function ROCKETS::HomingRocketThink(args)
{
  local rocket_entity = args[0];
  local target = args[1];
  local speed = args[2];

  if (!target.IsValid())
  {
    rocket_entity.Kill();

    return;
  }
  else
  {
    local current_dir = rocket_entity.GetForwardVector();

    local center = target.GetCenter();
    local bounds = target.GetBoundingMaxs();
    local targetPosBase = Vector(center.x, center.y, center.z - (bounds.z / 2));

    local targetDistance = (targetPosBase - rocket_entity.GetOrigin()).Length();
    local targetHeading = ROCKETS.HELPERS.NormalizeVector(target.GetAbsVelocity());
    local targetSpeed = target.GetAbsVelocity().Length();

    local speedDiff = targetSpeed - speed;
    local followSpeed = targetSpeed * ROCKETS.HOMING_ATTRS.ROCKET_FOLLOW_SPEED_MULTIPLIER;

    if (speed < followSpeed) speed = followSpeed;

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

		if (trace_output.hit) z_offset_distance = trace_output.fraction * z_offset_distance;

    local preferredTargetPosLow = Vector(targetPosBase_prediction.x, targetPosBase_prediction.y, targetPosBase_prediction.z - z_offset_distance);
    local preferredTargetPosHigh = Vector(targetPosBase_prediction.x, targetPosBase_prediction.y, targetPosBase_prediction.z - (z_offset_distance / 2));

    local futurePosition = targetPosBase_prediction;

    if ((targetPosBase.z < rocket_entity.GetOrigin().z) || (targetDistance > z_offset_distance * 2))
    {
      futurePosition = preferredTargetPosLow;
    }
    else if (targetDistance > z_offset_distance)
    {
      futurePosition = preferredTargetPosHigh;
    }

    local percentage = ROCKETS.HELPERS.ClampValue(
      ROCKETS.HELPERS.RangePercentage(ROCKETS.HOMING_ATTRS.MAX_TURNRATE_DISTANCE, ROCKETS.HOMING_ATTRS.MIN_TURNRATE_DISTANCE, targetDistance),
      0,
      100
    );
    local turnrate = ROCKETS.HELPERS.RangeValue(ROCKETS.HOMING_ATTRS.MAX_TURNRATE, ROCKETS.HOMING_ATTRS.MIN_TURNRATE, percentage);

    local target_direction = ROCKETS.HELPERS.CalculateDirectionToPosition(rocket_entity, futurePosition);
    local final_direction = ROCKETS.HELPERS.LerpVectors(current_dir, target_direction, turnrate);

    final_direction = ROCKETS.RocketCollision(rocket_entity, final_direction);

    rocket_entity.SetAbsVelocity(final_direction.Scale(speed));
    rocket_entity.SetForwardVector(final_direction);
  }
}

function ROCKETS::RocketCollision(rocket_entity, current_direction)
{
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
    if (normal.z > 0.5) return current_direction;

    scope.last_normal = normal;

    local percentage = trace_output.fraction * 100;
    local turnrate = ROCKETS.HELPERS.RangeValue(ROCKETS.HOMING_ATTRS.MAX_TURNRATE, ROCKETS.HOMING_ATTRS.MIN_TURNRATE, percentage);
    local target_direction = ROCKETS.HELPERS.NormalizeVector(current_dir + normal);

    return ROCKETS.HELPERS.LerpVectors(current_dir, target_direction, turnrate);
  }else{
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

function ROCKETS::CreateExplosion(rocket, damage)
{
  local explosion_entity = SpawnEntityFromTable("env_explosion", {
    spawnflags = 2,
    rendermode = 5
  });

  if (explosion_entity == null) return;

  NetProps.SetPropInt(explosion_entity, "m_iMagnitude", damage);
  NetProps.SetPropInt(explosion_entity, "m_iRadiusOverride", 100);

  explosion_entity.Teleport(
    true, rocket.GetOrigin(),
    false, QAngle(),
    false, Vector()
  );

  explosion_entity.AcceptInput("Explode", "", rocket, rocket);
  explosion_entity.Kill();
}
