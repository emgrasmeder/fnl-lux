(local character-render (require :shared.character.render))
(local compare (require :shared.testing.visual-compare))

(local CANVAS-W 160)
(local CANVAS-H 200)
(local FEET-Y (- CANVAS-H 10))
(local FEET-X (/ CANVAS-W 2))
(local FIGURE-H 36)

(local scenarios
  [{:name "phase0-right" :phase 0 :move-sign 1}
   {:name "phase1-right" :phase 1 :move-sign 1}
   {:name "phase0-left" :phase 0 :move-sign -1}
   {:name "phase1-left" :phase 1 :move-sign -1}])

(var update-fixtures? false)
(var scenario-idx 1)
(var exit-code 0)

(fn update-mode? []
  (let [v (os.getenv "UPDATE_VISUAL_FIXTURES")]
    (or update-fixtures?
        (and v (not= v "") (not= v "0")))))

(fn capture-scenario [scenario]
  (let [canvas (love.graphics.newCanvas CANVAS-W CANVAS-H)]
    (love.graphics.setCanvas canvas)
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    (character-render.render-stick-figure FEET-X FEET-Y FIGURE-H
                                          scenario.phase scenario.move-sign)
    (love.graphics.setCanvas)
    (canvas:newImageData)))

(fn process-scenario! [scenario]
  (let [actual (capture-scenario scenario)
        name scenario.name]
    (if (update-mode?)
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
  (when (<= scenario-idx (length scenarios))
    (process-scenario! (. scenarios scenario-idx))
    (set scenario-idx (+ scenario-idx 1)))
  (when (> scenario-idx (length scenarios))
    (love.event.quit exit-code)))
