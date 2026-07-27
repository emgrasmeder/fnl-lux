(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local visual (require :shared.testing.visual-runner))

(local WIN-W 560)
(local WIN-H 560)

(local scenarios
  [{:name "initial" :build (fn []
                              (math.randomseed 42)
                              (let [game (world-mod.create-game-world)
                                    state (systems.initial-state game)]
                                (values game state)))}
   {:name "after-step" :build (fn []
                                 (math.randomseed 42)
                                 (let [game (world-mod.create-game-world)
                                       state (systems.initial-state game)]
                                   (systems.step-once game state nil nil)
                                   (values game state)))}
   {:name "paused" :build (fn []
                             (math.randomseed 42)
                             (let [game (world-mod.create-game-world)
                                   state (systems.initial-state game)]
                               (tset state :phase :paused)
                               (values game state)))}])

(fn render-scenario! [scenario]
  (let [(game state) ((. scenario :build))
        canvas (visual.capture-window WIN-W WIN-H)]
    (ui.render game state)
    (visual.finish-capture canvas)))

(local loop (visual.make-loop scenarios render-scenario!))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
