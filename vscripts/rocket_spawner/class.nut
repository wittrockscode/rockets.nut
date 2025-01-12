class ROCKETS.SpawnedRocket
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
    this.Speed = (speed == null) ? ROCKETS.GLOBAL_ATTRS.ROCKET_SPEED : speed;
    this.Damage = (damage == null) ? ROCKETS.GLOBAL_ATTRS.ROCKET_DAMAGE : damage;
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
    this.SetPropData("string", "m_iName", "spawned_rocket");

    Entities.DispatchSpawn(this.Entity);

    this.SetPropData("int", "m_MoveType", 4);
    this.SetPropData("int", "m_nModelIndexOverrides", GetModelIndex("models/weapons/w_models/w_rocket.mdl"));
    this.SetPropData("int", "m_nNextThinkTick", -1);

    DoEntFire("!self", "Skin", "2", 0, null, this.Entity);
    AddParticles();

    this.Entity.SetAbsVelocity(this.Direction.Forward() * this.Speed);

    if (this.Explode)
    {
      SetDestroyCallback(this.Entity, this.Damage, function(damage)
      {
        ROCKETS.CreateExplosion(self, damage);
      })
    }

    if (this.Target)
    {
      local args = [this.Entity, this.Target, this.Speed];
      ROCKETS.HELPERS.AddThinkFunc(this.Entity, args, "HomingRocketThink", function(target, speed)
      {
        ROCKETS.HomingRocketThink(args);
      }, -1);
    }
    else
    {
      local args = [this.Entity];
      ROCKETS.HELPERS.AddThinkFunc(this.Entity, args, "DefaultRocketThink", function(target, speed)
      {
        ROCKETS.DefaultRocketThink(args);
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
      case "string":
        NetProps.SetPropString(this.Entity, str, val);
        break;
      default:
        return;
    }
  }

  function AddParticles()
  {
    local particle_entity = SpawnEntityFromTable("info_particle_system", {
      start_active = false,
      effect_name = ROCKETS.GLOBAL_ATTRS.PARTICLE_SYSTEM_NAME
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
