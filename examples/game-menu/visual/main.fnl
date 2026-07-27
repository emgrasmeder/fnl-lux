(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local visual (require :shared.testing.visual-runner))

(local WIN-W 640)
(local WIN-H 480)

(fn noop-callbacks []
  {:play (fn []) :exit (fn [])})

(local scenarios
  [{:name "focus-play" :build (fn [] (values (world-mod.create-menu-world) 1))}
   {:name "focus-exit" :build (fn []
                                (let [menu (world-mod.create-menu-world)
                                      state {:focused-index 1}]
                                  (systems.handle-key menu state (noop-callbacks) "down")
                                  (values menu state.focused-index)))}])

(fn render-scenario! [scenario]
  (let [(menu focused) ((. scenario :build))
        canvas (visual.capture-window WIN-W WIN-H)]
    (ui.render-menu menu focused)
    (visual.finish-capture canvas)))

(local loop (visual.make-loop scenarios render-scenario!))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
