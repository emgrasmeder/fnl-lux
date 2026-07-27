(local world (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local c (require :constants))
(local visual (require :shared.testing.visual-runner))

(local WIN-W c.WINDOW-W)
(local WIN-H c.WINDOW-H)

(local scenarios
  [{:name "round-1" :build (fn []
                             (math.randomseed 7)
                             (let [game (world.create-game-world 7)
                                   state (systems.initial-state)]
                               (values game state)))}
   {:name "summary" :build (fn []
                              (math.randomseed 7)
                              (let [game (world.create-game-world 7)
                                    state (systems.initial-state)]
                                (for [_ 1 c.TOTAL-ROUNDS]
                                  (systems.on-key game state "return"))
                                (values game state)))}])

(fn render-scenario! [scenario]
  (let [(game state) ((. scenario :build))
        canvas (visual.capture-window WIN-W WIN-H)]
    (ui.render game state)
    (visual.finish-capture canvas)))

(local loop (visual.make-loop scenarios render-scenario!))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
