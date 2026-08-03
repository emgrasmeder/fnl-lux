(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local visual (require :shared.testing.visual-runner))

(local WIN-W 680)
(local WIN-H 680)

(local scenarios
  [{:name "initial" :build (fn []
                              (math.randomseed 42)
                              (let [game (world-mod.create-game-world)
                                    state (systems.initial-state)]
                                (values game state)))}
   {:name "with-tower" :build (fn []
                                 (math.randomseed 42)
                                 (let [game (world-mod.create-game-world)
                                       state (systems.initial-state)]
                                   (systems.try-place-tower! game state 15 15)
                                   (values game state)))}
   {:name "with-creeps" :build (fn []
                                  (math.randomseed 42)
                                  (let [game (world-mod.create-game-world)
                                        state (systems.initial-state)]
                                    (systems.spawn-creep! game state)
                                    (systems.update-creeps! game state 0.5)
                                    (values game state)))}
   {:name "game-over" :build (fn []
                                (math.randomseed 42)
                                (let [game (world-mod.create-game-world)
                                      state (systems.initial-state)]
                                  (tset state :phase :ended)
                                  (tset state :escapes 10)
                                  (values game state)))}
   {:name "between-waves" :build (fn []
                                    (math.randomseed 42)
                                    (let [game (world-mod.create-game-world)
                                          state (systems.initial-state)]
                                      (tset state :wave-remaining 0)
                                      (tset state :phase :between-waves)
                                      (values game state)))}])

(fn render-scenario! [scenario]
  (let [(game state) ((. scenario :build))
        canvas (visual.capture-window WIN-W WIN-H)]
    (ui.render game state)
    (visual.finish-capture canvas)))

(local loop (visual.make-loop scenarios render-scenario!))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
