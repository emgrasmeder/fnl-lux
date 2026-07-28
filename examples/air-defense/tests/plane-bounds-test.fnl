(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local systems (require :systems))
(local stats-mod (require :stats))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create (. lux-world :create))
(local create-entity (. lux-world :create-entity))
(local get-table-by-id (. lux-world :get-table-by-id))

(fn empty-game []
  (let [w (create world.component-spec)]
    {:world w :turret-id 0 :building-ids []}))

(deftest off-screen-plane-repositions-into-sky-test
  (testing "alive plane past viewport edge moves to random sky"
    (math.randomseed 99)
    (let [game (empty-game)
          w game.world
          state (systems.initial-state game)
          pid (create-entity w [:actor :plane
                                :position -200 200
                                :velocity 0 0
                                :heading 0
                                :hp c.PLANE-HP
                                :team :red
                                :plane-ai :strafe 0 0 0])]
      (systems.step game state 0.016)
      (let [[x y] (. (get-table-by-id w pid) :position)]
        (assert-is (>= x 0))
        (assert-is (<= x c.WINDOW-W))
        (assert-is (>= y 0))
        (assert-is (< y c.GROUND-Y))))))

(deftest plane-heading-off-left-stays-on-screen-test
  (testing "edge avoidance keeps plane within horizontal bounds"
    (let [game (empty-game)
          w game.world
          state (systems.initial-state game)
          pid (create-entity w [:actor :plane
                                :position 50 200
                                :velocity 0 0
                                :heading math.pi
                                :hp c.PLANE-HP
                                :team :grey
                                :plane-ai :grey_cross 0 0 0])]
      (for [i 1 120]
        (systems.step game state 0.05))
      (let [[x _y] (. (get-table-by-id w pid) :position)]
        (assert-is (>= x (- c.PLANE-R 5)))
        (assert-is (<= x (+ c.WINDOW-W c.PLANE-R 5)))))))

(deftest plane-ground-crash-becomes-wreck-test
  (testing "alive plane crossing ground line wrecks"
    (let [game (empty-game)
          w game.world
          state (systems.initial-state game)
          pid (create-entity w [:actor :plane
                                :position 400 (- c.GROUND-Y 2)
                                :velocity 0 200
                                :heading (/ math.pi 2)
                                :hp c.PLANE-HP
                                :team :green
                                :plane-ai :hunt 0 0 0])]
      (systems.step game state 0.05)
      (let [comps (get-table-by-id w pid)]
        (assert-eq 0 (. comps.hp 1))
        (assert-eq :wreck (. comps.plane-ai 1))))))
