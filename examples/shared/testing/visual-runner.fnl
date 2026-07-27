(local compare (require :shared.testing.visual-compare))

(fn update-mode? [cli-flag?]
  (let [v (os.getenv "UPDATE_VISUAL_FIXTURES")]
    (or cli-flag?
        (and v (not= v "") (not= v "0")))))

(fn capture-window [w h]
  (let [canvas (love.graphics.newCanvas w h)]
    (love.graphics.setCanvas canvas)
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    canvas))

(fn finish-capture [canvas]
  (love.graphics.setCanvas)
  (canvas:newImageData))

(fn compare-or-save! [actual name update?]
  (if update?
      (compare.save-fixture! actual name)
      (let [(ok err) (pcall compare.image-data-equal? actual (compare.load-fixture-image name) name)]
        (when (not ok) (print err))
        ok)))

(fn make-loop [scenarios render-scenario!]
  (var cli-update? false)
  (var exit-code 0)
  (var processed? false)
  {:set-cli-update! (fn [v] (set cli-update? v))
   :love.load (fn [args]
                (love.graphics.setDefaultFilter "nearest" "nearest")
                (each [_ a (ipairs (or args []))]
                  (when (= a "--update-fixtures")
                    (set cli-update? true))))
   :love.draw (fn []
                (when (not processed?)
                  (set processed? true)
                  (each [_ scenario (ipairs scenarios)]
                    (let [name (. scenario :name)
                          actual (render-scenario! scenario)]
                      (when (and actual (not (compare-or-save! actual name (update-mode? cli-update?))))
                        (set exit-code 1))))
                  (love.event.quit exit-code)))})

{:update-mode? update-mode?
 :capture-window capture-window
 :finish-capture finish-capture
 :compare-or-save! compare-or-save!
 :make-loop make-loop}
