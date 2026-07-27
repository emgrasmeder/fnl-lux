(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))

(fn fresh-menu []
  (world.create-menu-world))

(fn noop-callbacks []
  {:play (fn []) :exit (fn [])})

(deftest handle-key-down-test
  (testing "handle-key down moves focus"
    (let [menu (fresh-menu)
          state {:focused-index 1}]
      (systems.handle-key menu state (noop-callbacks) "down")
      (assert-eq 2 state.focused-index))))

(deftest handle-key-up-wrap-test
  (testing "handle-key up wraps focus"
    (let [menu (fresh-menu)
          state {:focused-index 1}]
      (systems.handle-key menu state (noop-callbacks) "up")
      (assert-eq 2 state.focused-index))))

(deftest handle-key-return-test
  (testing "handle-key return activates focused button"
    (var played false)
    (let [menu (fresh-menu)
          state {:focused-index 1}]
      (systems.handle-key menu state {:play (fn [] (set played true))
                                      :exit (fn [])}
                          "return")
      (assert-is played))))
