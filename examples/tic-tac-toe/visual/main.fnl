(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local visual (require :shared.testing.visual-runner))

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

(fn render-scenario! [scenario]
  (let [(game state) ((. scenario :build))
        canvas (visual.capture-window WIN-W WIN-H)]
    (ui.render game state)
    (visual.finish-capture canvas)))

(fn on-load [_args] (math.randomseed 0))

(local loop (visual.make-loop scenarios render-scenario! on-load))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
