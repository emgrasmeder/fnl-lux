(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local run-updates (. world-api :run-updates))
(local world-mod (require :world))
(local tick (require :shared.tick))

(fn opposite-direction [direction]
  (case direction
    :up :down
    :down :up
    :left :right
    :right :left))

(fn direction-for-key [key]
  (case key
    "up" :up
    "down" :down
    "left" :left
    "right" :right
    "w" :up
    "s" :down
    "a" :left
    "d" :right))

(fn get-food-position [game]
  (let [components (get-table-by-id game.world game.food-id)]
    (when components
      {:row (. components.position 1)
       :col (. components.position 2)})))

(fn set-food-position! [game row col]
  (run-updates game.world {:position {game.food-id [row col]}}))

(fn set-player-position! [game row col direction]
  (run-updates game.world {:position {game.player-id [row col]}
                           :direction {game.player-id [direction]}}))

(fn copy-body-slice [body start stop]
  (var copy [])
  (for [i start stop]
    (table.insert copy (. body i)))
  copy)

(fn prepend-head [body head]
  (var new-body [head])
  (each [_ segment (ipairs body)]
    (table.insert new-body segment))
  new-body)

(fn trim-tail [body]
  (copy-body-slice body 1 (- (# body) 1)))

(fn self-collision? [body new-head eating]
  (let [check-until (if eating (# body) (- (# body) 1))]
    (var hit false)
    (for [i 1 check-until]
      (when (world-mod.positions-equal? (. body i) new-head)
        (set hit true)))
    hit))

(fn wall-collision? [row col]
  (not (world-mod.playable? row col)))

(fn score [state] (# state.body))

(fn overlay-text [state]
  (case state.phase
    :paused "PAUSED"
    :ended "Game Over — press R"
    _ nil))

(fn initial-state [game]
  {:phase :playing
   :body game.initial-body
   :direction game.initial-direction
   :next-direction game.initial-direction
   :step-timer 0})

(fn apply-direction [state direction]
  (when (and direction (= state.phase :playing)
               (not= direction (opposite-direction state.direction)))
    (tset state :next-direction direction)))

(fn toggle-pause [state]
  (case state.phase
    :playing (tset state :phase :paused)
    :paused (tset state :phase :playing)
    _ nil))

(fn spawn-food! [game state]
  (let [food-pos (world-mod.pick-food-position state.body)]
    (when food-pos
      (set-food-position! game (. food-pos :row) (. food-pos :col))
      food-pos)))

(fn advance-step! [game state on-eat on-death]
  (when (= state.phase :playing)
    (tset state :direction state.next-direction)
    (let [direction state.direction
          [dr dc] (world-mod.direction-delta direction)
          head (. state.body 1)
          new-head {:row (+ (. head :row) dr)
                    :col (+ (. head :col) dc)}
          food-pos (get-food-position game)
          eating (and food-pos (world-mod.positions-equal? new-head food-pos))]
      (if (wall-collision? (. new-head :row) (. new-head :col))
          (do
            (tset state :phase :ended)
            (when on-death (on-death))
            :ended)
          (if (self-collision? state.body new-head eating)
              (do
                (tset state :phase :ended)
                (when on-death (on-death))
                :ended)
              (let [new-body (if eating
                               (prepend-head state.body new-head)
                               (trim-tail (prepend-head state.body new-head)))]
                (tset state :body new-body)
                (when eating
                  (when on-eat (on-eat))
                  (spawn-food! game state))
                (set-player-position! game (. new-head :row) (. new-head :col) direction)
                (if eating :ate :moved)))))))

(fn step-once [game state on-eat on-death]
  (advance-step! game state on-eat on-death))

(fn step [game state dt on-eat on-death]
  (when (= state.phase :playing)
    (tick.step-on-interval state dt 1.0
      (fn [] (advance-step! game state on-eat on-death)))))

{:opposite-direction opposite-direction
 :direction-for-key direction-for-key
 :get-food-position get-food-position
 :score score
 :overlay-text overlay-text
 :initial-state initial-state
 :apply-direction apply-direction
 :toggle-pause toggle-pause
 :spawn-food! spawn-food!
 :advance-step! advance-step!
 :step-once step-once
 :step step
 :wall-collision? wall-collision?
 :self-collision? self-collision?
 :prepend-head prepend-head
 :trim-tail trim-tail}
