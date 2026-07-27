(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local compare (require :shared.testing.visual-compare))

(local WIN-W 480)
(local WIN-H 480)

(fn cell-center [row col]
  (let [[x y w h] (world-mod.cell-bounds-at row col)]
    [(+ x (/ w 2)) (+ y (/ h 2))]))

(fn apply-outcome! [state outcome]
  (when outcome
    (case (. outcome :result)
      :win (do
             (tset state :phase :ended)
             (tset state :message (.. (systems.player-label (. outcome :winner)) " wins!"))
             (tset state :current-player (. outcome :winner)))
      :draw (do
              (tset state :phase :ended)
              (tset state :message "Draw!")
              (tset state :current-player state.current-player))
      :continue (tset state :current-player (. outcome :next-player)))))

(fn click-cell! [game state row col]
  (let [[mx my] (cell-center row col)]
    (apply-outcome! state (systems.handle-click game state mx my))))

(local scenarios
  [{:name "empty-board" :build (fn [] (values (world-mod.create-game-world)
                                               {:current-player :X :phase :playing :message nil}))}
   {:name "x-center" :build (fn []
                               (let [game (world-mod.create-game-world)
                                     state {:current-player :X :phase :playing :message nil}
                                     [mx my] (cell-center 1 1)]
                                 (systems.handle-click game state mx my)
                                 (values game state)))}
   {:name "x-and-o" :build (fn []
                             (let [game (world-mod.create-game-world)
                                   state {:current-player :X :phase :playing :message nil}]
                               (click-cell! game state 1 1)
                               (click-cell! game state 2 2)
                               (values game state)))}
   {:name "win-x-row" :build (fn []
                                (let [game (world-mod.create-game-world)]
                                  (systems.apply-move game :X 1 1)
                                  (systems.apply-move game :O 2 2)
                                  (systems.apply-move game :X 1 2)
                                  (systems.apply-move game :O 2 1)
                                  (let [state {:current-player :X :phase :playing :message nil}
                                        [mx my] (cell-center 1 3)]
                                    (apply-outcome! state (systems.handle-click game state mx my))
                                    (values game state))))}])

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

(fn update-mode? []
  (let [v (os.getenv "UPDATE_VISUAL_FIXTURES")]
    (or update-fixtures?
        (and v (not= v "") (not= v "0")))))

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
  (math.randomseed 0)
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
