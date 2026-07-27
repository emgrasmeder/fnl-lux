(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local c (require :constants))

(deftest on-wheel-chain-len-test
  (testing "on-wheel adjusts chain length"
    (math.randomseed 7)
    (let [game (world.create-game-world 7)
          state (systems.initial-state)
          start (. (. game :physics) :chain-len)]
      (systems.on-wheel game state 1)
      (assert-eq (+ start c.CHAIN-WHEEL-STEP) (. (. game :physics) :chain-len)))))
