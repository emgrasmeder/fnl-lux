(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local visual (require :shared.testing.visual-runner))
(local c (require :constants))

(local scenarios
  [{:name "initial" :build (fn []
                              (math.randomseed 42)
                              (let [game (world-mod.create-game-world)
                                    state (systems.initial-state game)]
                                (values game state)))}
   {:name "after-tick" :build (fn []
                                 (math.randomseed 42)
                                 (let [game (world-mod.create-game-world)
                                       state (systems.initial-state game)]
                                   (systems.step game state 0.05)
                                   (values game state)))}])

(fn render-scenario! [scenario]
  (let [(game state) ((. scenario :build))
        canvas (visual.capture-window c.WINDOW-W c.WINDOW-H)]
    (ui.render game state)
    (visual.finish-capture canvas)))

(local loop (visual.make-loop scenarios render-scenario!))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
