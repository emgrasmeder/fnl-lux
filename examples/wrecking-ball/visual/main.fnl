(local world (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local c (require :constants))
(local compare (require :shared.testing.visual-compare))

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

(fn capture-scenario [scenario]
  (let [(game state) ((. scenario :build))
        canvas (love.graphics.newCanvas WIN-W WIN-H)]
    (love.graphics.setCanvas canvas)
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    (ui.render game state)
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
