(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local systems (require :systems))
(local love-mock (require :shared.testing.love-mock))

(deftest on-key-jump-test
  (testing "on-key sets jump-request on space"
    (let [state (systems.initial-state)]
      (systems.on-key state "space")
      (assert-eq true state.jump-request))))

(deftest horizontal-input-test
  (testing "horizontal-input reads keyboard"
    (love-mock.install!)
    (love-mock.clear-input!)
    (love-mock.set-keys-down! "d" true)
    (assert-eq 1 (systems.horizontal-input))
    (love-mock.clear-input!)
    (love-mock.set-keys-down! "a" true)
    (assert-eq -1 (systems.horizontal-input))
    (love-mock.uninstall!)))
