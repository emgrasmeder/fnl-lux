(local c (require :constants))
(local terrain (require :terrain))

(fn pane-key [index] index)

(fn ensure-pane! [state index entry-y]
  (when (not (. state.panes index))
    (tset state.panes index (terrain.generate-pane index entry-y))))

(fn ensure-panes-ahead! [state player-x]
  (when (not (. state.panes 0))
    (ensure-pane! state 0 c.FLOOR_BASE))
  (let [current-pane (math.floor (/ player-x c.PANE_W))
        target (+ current-pane c.PANES_AHEAD)]
    (for [i 1 target]
      (when (not (. state.panes i))
        (let [prev (. state.panes (- i 1))]
          (when prev
            (ensure-pane! state i (. prev :exit-y))))))))

(fn unload-old-panes! [state]
  (let [cutoff (math.floor (/ state.world-min-x c.PANE_W))]
    (each [idx _ (pairs state.panes)]
      (when (< idx cutoff)
        (tset state.panes idx nil)))))

(fn all-segments [state]
  (var segments [])
  (each [_ pane (pairs state.panes)]
    (when pane
      (each [_ seg (ipairs pane.segments)]
        (table.insert segments seg))))
  segments)

(fn segments-near [state x radius]
  (let [lo (- x radius)
        hi (+ x radius)
        out []]
    (each [_ pane (pairs state.panes)]
      (when pane
        (each [_ seg (ipairs pane.segments)]
          (when (and (<= seg.x1 hi) (>= seg.x2 lo))
            (table.insert out seg)))))
    out))

(fn update-camera! [state player-x]
  (let [target (- player-x c.CAMERA_LEAD)]
    (when (> target state.camera-x)
      (tset state :camera-x target))
    (when (> state.camera-x state.world-min-x)
      (tset state :world-min-x state.camera-x))
    (unload-old-panes! state)))

(fn clamp-player-x [x world-min-x]
  (math.max x world-min-x))

(fn initial-state []
  {:panes {}
   :camera-x 0
   :world-min-x 0})

{:ensure-pane! ensure-pane!
 :ensure-panes-ahead! ensure-panes-ahead!
 :unload-old-panes! unload-old-panes!
 :all-segments all-segments
 :segments-near segments-near
 :update-camera! update-camera!
 :clamp-player-x clamp-player-x
 :initial-state initial-state}
