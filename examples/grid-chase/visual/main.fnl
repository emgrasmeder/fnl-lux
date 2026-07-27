(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local compare (require :shared.testing.visual-compare))

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
                                   (systems.step-once game state nil)
                                   (values game state)))}])

(fn capture-scenario [scenario]
  (let [(game state) ((. scenario :build))
        canvas (love.graphics.newCanvas WIN-W WIN-H)]
    (love.graphics.setCanvas canvas)
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    (ui.render game)
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
