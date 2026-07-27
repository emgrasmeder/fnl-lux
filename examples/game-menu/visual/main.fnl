(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local compare (require :shared.testing.visual-compare))

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

(fn capture-scenario [scenario]
  (let [(menu focused) ((. scenario :build))
        canvas (love.graphics.newCanvas WIN-W WIN-H)]
    (love.graphics.setCanvas canvas)
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    (ui.render-menu menu focused)
    (love.graphics.setCanvas)
    (canvas:newImageData)))

(var update-fixtures? false)
(var exit-code 0)
(var processed? false)

(fn process-scenario! [scenario]
  (let [actual (capture-scenario scenario)
        name scenario.name]
    (if (or update-fixtures? (let [v (os.getenv "UPDATE_VISUAL_FIXTURES")]
                                (and v (not= v "") (not= v "0"))))
        (compare.save-fixture! actual name)
        (let [(ok err) (pcall compare.image-data-equal? actual (compare.load-fixture-image name) name)]
          (when (not ok)
            (print err)
            (set exit-code 1))))))

(fn love.load [args]
  (love.graphics.setDefaultFilter "nearest" "nearest")
  (each [_ a (ipairs (or args []))]
    (when (= a "--update-fixtures")
      (set update-fixtures? true))))

(fn love.draw []
  (when (not processed?)
    (set processed? true)
    (each [_ scenario (ipairs scenarios)]
      (let [(ok err) (pcall process-scenario! scenario)]
        (when (not ok)
          (print err)
          (set exit-code 1))))
    (love.event.quit exit-code)))
