::CreateExplosion <- function(rocket, damage)
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
