(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))

(fn fresh-game []
  (world.create-game-world))

(deftest logical-cell-from-position-test
  (testing "logical cell picks nearest center"
    (let [[cx cy] (world.cell-center-at 5 5)]
      (assert-eq 5 (. (systems.logical-cell-from-position cx cy 5 5) :row))
      (assert-eq 5 (. (systems.logical-cell-from-position cx cy 5 5) :col))
      (let [cell (systems.logical-cell-from-position
                  (+ cx 1) cy 5 6)]
        (assert-eq 5 (. cell :row))
        (assert-eq 5 (. cell :col))))))

(deftest spawn-and-repath-test
  (testing "spawned creep gets a path toward the left"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.spawn-creep! game state)
      (assert-eq 1 (# state.creep-ids))
      (let [id (. state.creep-ids 1)
            creep-data (. state.creep-paths id)]
        (assert-is creep-data)
        (assert-is (. creep-data :path))
        (assert-is (> (# (. creep-data :path)) 1))))))

(deftest wave-starts-with-configured-count-test
  (testing "first wave remaining matches waves.fnl"
    (math.randomseed 1)
    (let [state (systems.initial-state)
          def (systems.wave-def 1)]
      (assert-eq 1 state.wave-index)
      (assert-eq (. def :count) state.wave-remaining)
      (assert-eq 10 state.wave-remaining)
      (assert-is state.wave-spawn-row)
      (assert-eq :playing state.phase))))

(deftest wave-spawns-from-one-row-test
  (testing "all creeps in a wave share the spawn row"
    (math.randomseed 7)
    (let [game (fresh-game)
          state (systems.initial-state)
          row state.wave-spawn-row]
      (tset state :wave-remaining 3)
      (tset state :spawn-timer world.SPAWN-INTERVAL)
      (systems.update-spawn! game state 0)
      (systems.update-spawn! game state world.SPAWN-INTERVAL)
      (systems.update-spawn! game state world.SPAWN-INTERVAL)
      (assert-eq 3 (# state.creep-ids))
      (assert-eq 0 state.wave-remaining)
      (each [_ id (ipairs state.creep-ids)]
        (let [components (get-table-by-id game.world id)]
          (assert-eq row (. components.grid-pos 1))
          (assert-eq world.RIGHT-COL (. components.grid-pos 2)))))))

(deftest enter-advances-wave-test
  (testing "Enter starts the next wave after clearance"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (tset state :wave-remaining 0)
      (tset state :creep-ids [])
      (systems.check-wave-complete! state)
      (assert-eq :between-waves state.phase)
      (systems.handle-key game state "return")
      (assert-eq 2 state.wave-index)
      (assert-eq :playing state.phase)
      (assert-eq (. (systems.wave-def 2) :count) state.wave-remaining))))

(deftest place-tower-test
  (testing "placing a tower updates terrain and repaths"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.spawn-creep! game state)
      (assert-is (systems.try-place-tower! game state 15 15))
      (assert-eq :tower (. game.terrain (world.cell-key 15 15))))))

(deftest escape-ends-game-test
  (testing "10 escapes ends the game"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (tset state :escapes 9)
      (systems.update-creeps! game state 0)
      (tset state :escapes 10)
      (tset state :phase :ended)
      (assert-eq :ended state.phase))))

(deftest move-toward-test
  (testing "move-toward reaches target within one step"
    (let [[x y arrived] (systems.move-toward 0 0 10 0 10 1)]
      (assert-is arrived)
      (assert-eq 10 x)
      (assert-eq 0 y))))

(deftest creep-escape-on-left-opening-test
  (testing "creep on left opening counts as escape"
    (let [game (fresh-game)
          state (systems.initial-state)
          opening (. (world.left-opening-cells) 1)
          [x y] (world.cell-center-at (. opening :row) (. opening :col))
          id (world.create-entity game.world [:position x y
                                               :grid-pos (. opening :row) (. opening :col)
                                               :creep])]
      (tset state :creep-ids [id])
      (tset state :creep-paths id {:path [{:row (. opening :row) :col (. opening :col)}]
                                   :path-idx 1})
      (tset state :wave-remaining 1)
      (systems.update-creeps! game state 0)
      (assert-eq 1 state.escapes)
      (assert-eq 0 (# state.creep-ids)))))
