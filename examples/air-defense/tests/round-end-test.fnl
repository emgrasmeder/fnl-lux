(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create (. lux-world :create))
(local create-entity (. lux-world :create-entity))
(local run-updates (. lux-world :run-updates))

(fn empty-game []
  (let [w (create world.component-spec)]
    {:world w :turret-id 0 :building-ids []}))

(deftest empty-sky-early-victory-test
  (testing "no alive planes ends round with victory"
    (let [game (empty-game)
          w game.world
          state (systems.initial-state game)
          pid (create-entity w [:actor :plane
                                :position 400 200
                                :velocity 0 0
                                :heading 0
                                :hp c.PLANE-HP
                                :team :red
                                :plane-ai :strafe 0 0 0])]
      (run-updates w {:hp {pid [0]}
                      :plane-ai {pid [:wreck 0 0 0]}})
      (systems.step game state 0.016)
      (assert-eq :summary (. state :phase))
      (assert-eq :win (. state :outcome)))))
