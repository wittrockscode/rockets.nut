# rockets.nut

VScript for spawning rockets that collide with players.
Place `vscripts` folder in `tf\scripts` folder to get started.
Prefab with all necessary entities and examples is included (`rockets_prefab.vmf`).

## Using the script

To use the script in a map, add a `logic_script` entity with the Entity Scripts field set to `rockets.nut` and with the name field set to `script`.
You can set defaults for various values either by editing the `rockets.nut` file, or by adding a `logic_timer` entity with the following outputs to your map (add the attributes you want to set to the function parameters):
```
| My Output | Target Entity | Target Input  | Parameter                                           | Delay |
|-----------|---------------|---------------|------------------------------------------------------|-------|
| OnTimer   | script        | RunScriptCode | SetAttributes({rocket_damage=90,rocket_speed=1100})  | 0.00  |
```
Rockets will use these values if you don't specify them in the spawn functions.
Attributes you can set:

| Name | Default |
|--|--|
| ROCKET_DAMAGE   | 90.0 |
| ROCKET_SPEED  | 1100 |
| ROCKET_COLLISION_AVOIDANCE | true |
| ROCKET_TARGET_PREDICTION | true |
| PARTICLE_SYSTEM_NAME | "critical_rocket_blue" |
| ROCKET_BOUNDS_P | Vector(18.3205, 3.417, 3.417) |
| ROCKET_FOLLOW_SPEED_MULTIPLIER | 2 |
| ROCKET_EXPLODE | true |
| MAX_TURNRATE | 0.7 |
| MIN_TURNRATE | 0.23 |
| MAX_TURNRATE_DISTANCE | 50 |
| MIN_TURNRATE_DISTANCE | 400 |

## Funtions

All functions have an optional parameter `parameters`, where you can set the properties of the rocket:
| Name | Type |
|--|--|
| speed | float |
| damage | float |
| explode | bool |
| target | string |
| scale | float |
| follow_speed_multiplier | float |
| collision_avoidance | bool |
| target_prediction | bool |

You can set these by using this structure in your function call:
```
SpawnRocketAtEntityHoming(`spawn_entity_name`, {target=`target_entity_name`,damage=90.0,speed=1100.0,explode=false})
```
*Note: To use strings in parameters, you have to use backticks (`).*

Omitting the `target` parameter when spawning a homing rocket sets the `!activator` as the target.

###  SpawnRocketAtEntity
Spawns a rocket at the location of an entity.

#### Arguments
```
| name             | type   | required |
|------------------|--------|----------|
| spawn_point_name | string | yes      |
| parameters       | table  | no       |
```
#### Usage

Create an `info_target` with a specific name and the angle at which the rocket will fly at. For this example, the name is set to `rocket1`.
Then, create something that will fire an output when you want to spawn the rocket, for example a `trigger_multiple` or a `func_button`. (`func_button` in this example)
Fill it with this output:
```
| My Output | Target Entity | Target Input  | Parameter                       | Delay |
|-----------|---------------|---------------|---------------------------------|-------|
| OnPressed | script        | RunScriptCode | SpawnRocketAtEntity(`rocket1`)  | 0.00  |
```

### SpawnRocketAtEntityHoming
Same as `SpawnRocketAtEntity`, but the rockets are homing.
#### Arguments
```
| name               | type   | required |
|--------------------|--------|----------|
| spawn_point_name   | string | yes      |
| parameters         | table  | no       |
```

### ReplaceRocket

Replaces a user fired rocket.
#### Arguments
```
| name             | type   | required |
|------------------|--------|----------|
| parameters       | table  | no       |
```
#### Usage

Create a `trigger_multiple` with the `Everything (not including physics debris)` flag checked and the `Clients` flag unchecked. You need to have a filter for rocket projectiles set, so nothing else will trigger this. More about this later.
Add this output:
```
| My Output    | Target Entity | Target Input  | Parameter        | Delay |
|--------------|---------------|---------------|------------------|-------|
| OnStartTouch | script        | RunScriptCode | ReplaceRocket()  | 0.00  |
```
You can use this in combination with a `trigger_push` to reflect rockets back to the player that damage him.

### ReplaceRocketHoming
Same as `ReplaceRocket`, but the rockets are homing.
#### Arguments
```
| name               | type   | required |
|--------------------|--------|----------|
| parameters         | table  | no       |
```

## Filters
To filter for normal rockets, add two `filter_activator_class`, a `filter_activator_name` and two `filter_multi`entities with these settings to you map:

#### first `filter_activator_class`
```
| Name        | is_stock_rocket           |
| Filter mode | Allow ...                 |
| Filter Name | tf_projectile_rocket      |
```
#### second `filter_activator_class`
```
| Name        | is_cowmangler_rocket      |
| Filter mode | Allow ...                 |
| Filter Name | tf_projectile_energy_ball |
```
#### `filter_activator_name`
```
| Name        | is_not_spawned            |
| Filter mode | Disallow ...              |
| Filter Name | spawned_rocket            |
```
The `Filter Name`will be red, this is normal.
#### first `filter_multi`
```
| Name        | is_rocket                |
| Logic Type  | AND                      |
| Filter 1    | is_stock_rocket          |
| Filter 2    | is_cowmangler_rocket     |
```
#### second `filter_multi`
```
| Name        | is_natural_rocket        |
| Logic Type  | AND                      |
| Filter 1    | is_rocket                |
| Filter 2    | is_not_spawned           |
```
---
Then, add the `is_natural_rocket` to any `trigger_multiple` or wherever you want to filter for normal rockets.
To filter for spawned rockets, add a `filter_activator_name` with Filter Name set to `spawned_rocket`.
