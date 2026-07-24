(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local run-updates (. world-api :run-updates))
(local c (require :constants))
(local physics (require :physics))
(local camera (require :camera))
(local walk (require :shared.character.walk))

(fn key-held? [key]
  (let [is-down (when (and _G.love _G.love.keyboard)
                   (. _G.love.keyboard :isDown))]
    (and is-down (is-down key))))

(fn horizontal-input []
  (var dir 0)
  (when (or (key-held? "left") (key-held? "a"))
    (set dir (- dir 1)))
  (when (or (key-held? "right") (key-held? "d"))
    (set dir (+ dir 1)))
  dir)

(fn player-state [game]
  (let [components (get-table-by-id game.world game.player-id)]
    (when components
      {:x (. components.position 1)
       :y (. components.position 2)
       :vx (. components.velocity 1)
       :vy (. components.velocity 2)
       :grounded (. components.grounded 1)})))

(fn sync-player! [game pos vel grounded?]
  (run-updates game.world
               {:position {game.player-id [(. pos :x) (. pos :y)]}
                :velocity {game.player-id [(. vel :vx) (. vel :vy)]}
                :grounded {game.player-id [grounded?]}}))

(fn initial-state []
  {:jump-request false
   :walk (walk.initial-walk-state)})

(fn on-key [state key]
  (when (= key "space")
    (tset state :jump-request true)))

(fn step [game state dt]
  (let [ps (player-state game)
        pos {:x ps.x :y ps.y}
        vel {:vx ps.vx :vy ps.vy}
        move-dir (horizontal-input)
        was-grounded ps.grounded]
    (physics.apply-horizontal-input vel move-dir was-grounded)
    (when state.jump-request
      (physics.jump! vel was-grounded)
      (tset state :jump-request false))
    (physics.integrate pos vel dt was-grounded)
    (camera.ensure-panes-ahead! game.cam-state (. pos :x))
    (let [segments (camera.segments-near game.cam-state (. pos :x) c.PANE_W)
          grounded (physics.collide-capsule pos vel segments)]
      (tset pos :x (camera.clamp-player-x (. pos :x) game.cam-state.world-min-x))
      (sync-player! game pos vel grounded)
      (camera.update-camera! game.cam-state (. pos :x))
      (tset state :walk (walk.advance-walk-state state.walk (. vel :vx) grounded dt
                                                   c.WALK_STEP_PX c.WALK_VX_EPSILON)))))

{:initial-state initial-state
 :step step
 :on-key on-key
 :player-state player-state
 :horizontal-input horizontal-input}
