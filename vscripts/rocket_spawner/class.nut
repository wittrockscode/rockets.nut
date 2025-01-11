class SpawnedRocket
{
  Entity      = null; // Entity
  Position    = null; // Vector
  Direction   = null; // QAngle
  Speed       = null; // int
  Damage      = null; // float
  Explode     = null; // bool
  Target      = null; // Entity

  constructor(position, direction, speed, damage, explode, target = null)
  {
    this.Entity = Entities.CreateByClassname("tf_projectile_rocket");
    this.Position = position;
    this.Direction = direction;
    this.Speed = (speed == null) ? GLOBAL_ATTRS.ROCKET_SPEED : speed;
    this.Damage = (damage == null) ? GLOBAL_ATTRS.ROCKET_DAMAGE : damage;
    this.Explode = (explode == null) ? true : explode;
    this.Target = target;

    this.Entity.Teleport(
      true, this.Position,
      true, this.Direction,
      false, Vector()
    );

    this.SetPropData("int", "m_bCritical", 0);
    this.SetPropData("int", "m_iTeamNum", 1);
    this.SetPropData("int", "m_iDeflected", 0);
    this.SetPropData("ent", "m_hOriginalLauncher", this.Entity);
    this.SetPropData("ent", "m_hLauncher", this.Entity);

    Entities.DispatchSpawn(this.Entity);

    this.SetPropData("int", "m_MoveType", 4);
    this.SetPropData("int", "m_nModelIndexOverrides", GetModelIndex("models/weapons/w_models/w_rocket.mdl"));
    this.Entity.AcceptInput("targetname", "spawned_rocket", this.Entity, this.Entity);

    DoEntFire("!self", "Skin", "2", 0, null, this.Entity);
    AddParticles();

    this.Entity.SetAbsVelocity(this.Direction.Forward() * this.Speed);

    if (this.Explode)
    {
      SetDestroyCallback(this.Entity, this.Damage, function(damage)
      {
        CreateExplosion(self, damage);
      })
    }

    if (this.Target)
    {
      this.SetPropData("int", "m_nNextThinkTick", -1);

      HookCustomThink(this.Entity, this.Target, this.Speed, "SPWNR_HomingRocketThink", function(target, speed)
      {
        HomingRocketThink(self, target, speed);
      }, -1);
    }
  }

  function SetPropData(type, str, val)
  {
    switch(type)
    {
      case "int":
        NetProps.SetPropInt(this.Entity, str, val);
        break;
      case "float":
        NetProps.SetPropFloat(this.Entity, str, val);
        break;
      case "ent":
        NetProps.SetPropEntity(this.Entity, str, val);
        break;
      default:
        return;
    }
  }

  function AddParticles()
  {
    local particle_entity = SpawnEntityFromTable("info_particle_system", {
      start_active = false,
      effect_name = "eyeboss_projectile"
    });

    if (particle_entity == null) return;

    particle_entity.Teleport(
      true, this.Entity.GetOrigin(),
      true, this.Entity.GetAbsAngles(),
      false, Vector()
    );
    particle_entity.AcceptInput("SetParent", "!activator", this.Entity, particle_entity);
    if (this.Entity.LookupAttachment("trail") != 0)
    {
      particle_entity.AcceptInput("SetParentAttachment", "trail", null, particle_entity);
    }

    particle_entity.AcceptInput("Start", "", this.Entity, particle_entity);
  }

  // https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/Script_Functions#Hooks_2
  function SetDestroyCallback(entity, damage, callback)
  {
    entity.ValidateScriptScope()
    local scope = entity.GetScriptScope()
    scope.setdelegate({}.setdelegate({
        parent   = scope.getdelegate()
        id       = entity.GetScriptId()
        index    = entity.entindex()
        callback = callback
        _get = function(k)
        {
          return parent[k]
        }
        _delslot = function(k)
        {
          if (k == id)
          {
            entity = EntIndexToHScript(index)
            local scope = entity.GetScriptScope()
            scope.self <- entity
            callback.pcall(scope, damage)
          }
          delete parent[k]
        }
      })
    )
  }
}

::HomingRocketThink <- function(rocket_entity, target, speed)
{
  if (!IsValidClient(target))
  {
    rocket_entity.Kill();

    return;
  }
  else
  {
    local rocket_speed = 2.0;
    local max_turnrate = 0.7;
    local min_turnrate = 0.23;
    local turnrate_max_distance = 50;
    local turnrate_min_distance = 400;
    local current_dir = rocket_entity.GetForwardVector();

    local center = target.GetCenter();
    local bounds = target.GetBoundingMaxs();
    local feet = Vector(center.x, center.y, center.z - (bounds.z / 2));

    local targetDistance = (feet - rocket_entity.GetOrigin()).Length();

    local targetHeading = NormalizeVector(target.GetAbsVelocity());
    local targetSpeed = target.GetAbsVelocity().Length();

    local speedDiff = targetSpeed - speed;

    local speed_increase = 0;

    if (speed < targetSpeed * rocket_speed) {
      speed_increase = targetSpeed * rocket_speed - speed;
    }

    local timeToImpact = targetDistance / (speed + speed_increase);
    local feet_future_position = feet + targetHeading.Scale(targetSpeed * timeToImpact);
    local under_feet_1_future_position = Vector(feet_future_position.x, feet_future_position.y, feet_future_position.z - bounds.z);
    local under_feet_2_future_position = Vector(feet_future_position.x, feet_future_position.y, feet_future_position.z - (bounds.z / 2));

    local futurePosition = 0;

    if (feet.z < rocket_entity.GetOrigin().z){
      futurePosition = under_feet_1_future_position;
    }
    else if (targetDistance > bounds.z * 2){
      futurePosition = under_feet_1_future_position;
    }
    else if (targetDistance > bounds.z){
      futurePosition = under_feet_2_future_position;
    }
    else{
      futurePosition = feet_future_position;
    }

    local percentage = ClampValue(RangePercentage(turnrate_max_distance, turnrate_min_distance, targetDistance), 0, 100);
    local turnrate = RangeValue(max_turnrate, min_turnrate, percentage);

    local target_dir = CalculateDirectionToPosition(rocket_entity, futurePosition);
    local dir = LerpVectors(current_dir, target_dir, turnrate);

    rocket_entity.SetAbsVelocity(dir.Scale(speed + speed_increase));
    rocket_entity.SetForwardVector(dir);
  }
}