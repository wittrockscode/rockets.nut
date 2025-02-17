class ROCKETS.SpawnedRocket {
  Entity                  = null; // Entity
  Position                = null; // Vector
  Direction               = null; // QAngle
  BaseSpeed               = null; // int
  Damage                  = null; // float
  Explode                 = null; // bool
  Target                  = null; // Entity
  Scale                   = null; // float
  FollowSpeedMultiplier   = null; // float
  CollisionAvoidance      = null; // bool
  TargetPrediction        = null; // bool
  Homing                  = null; // bool
  DamageEveryone          = null; // bool

  constructor(args) {
    this.Entity                 = Entities.CreateByClassname("tf_projectile_rocket");
    this.Position               = args.position;
    this.Direction              = args.direction;
    this.BaseSpeed              = args.speed;
    this.Damage                 = args.damage;
    this.Explode                = args.explode;
    this.Target                 = args.target;
    this.Scale                  = args.scale;
    this.FollowSpeedMultiplier  = args.follow_speed_multiplier;
    this.CollisionAvoidance     = args.collision_avoidance;
    this.TargetPrediction       = args.target_prediction;
    this.Homing                 = args.homing;
    this.DamageEveryone         = args.damage_everyone;

    args = null;

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
    this.SetPropData("int", "m_CollisionGroup", 24);
    this.SetPropData("int", "m_MoveType", 4);
    this.SetPropData("int", "m_nModelIndexOverrides", GetModelIndex("models/weapons/w_models/w_rocket.mdl"));
    this.SetPropData("int", "m_nNextThinkTick", -1);
    this.SetPropData("float", "m_flModelScale", this.Scale);

    Entities.DispatchSpawn(this.Entity);
    this.Entity.SetSize(ROCKETS.Globals.ROCKET_BOUNDS_P * this.Scale * -1, ROCKETS.Globals.ROCKET_BOUNDS_P * this.Scale);
    this.Entity.SetAbsVelocity(this.Direction.Forward() * this.BaseSpeed);
    AddCustomParticle();

    if (this.Explode) {
      SetDestroyCallback(this, function(entity, rocket) {
        ROCKETS.CreateExplosion(entity, rocket);
      });
    }

    if (this.Homing) {
      ROCKETS.Helpers.AddThinkFunc(this.Entity, this, "HomingRocketThink", function(rocket) {
        ROCKETS.HomingRocketThink(rocket);
      }, -1);
    } else {
      ROCKETS.Helpers.AddThinkFunc(this.Entity, this, "DefaultRocketThink", function(rocket) {
        ROCKETS.DefaultRocketThink(rocket);
      }, -1);
    }
  }

  function SetPropData(type, str, val) {
    switch(type) {
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

  function AddCustomParticle() {
    local particle_entity = SpawnEntityFromTable("info_particle_system", {
      start_active = false,
      effect_name = ROCKETS.Globals.PARTICLE_SYSTEM_NAME
    });

    if (particle_entity == null) return;

    particle_entity.Teleport(
      true, this.Entity.GetOrigin(),
      true, this.Entity.GetAbsAngles(),
      false, Vector()
    );
    particle_entity.AcceptInput("SetParent", "!activator", this.Entity, particle_entity);
    particle_entity.AcceptInput("SetParentAttachment", "trail", null, particle_entity);
    particle_entity.AcceptInput("Start", "", this.Entity, particle_entity);
  }

  // https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/Script_Functions#Hooks_2
  function SetDestroyCallback(rocket, callback){
    local entity = rocket.Entity;
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
            callback.pcall(scope, entity, rocket)
          }
          delete parent[k]
        }
      })
    )
  }
}
