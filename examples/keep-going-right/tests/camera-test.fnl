(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local c (require :constants))
(local camera (require :camera))

(deftest ensure-panes-ahead-test
  (testing "panes generate ahead of player"
    (math.randomseed 3)
    (let [state (camera.initial-state)]
      (camera.ensure-panes-ahead! state 0)
      (assert-is (. state.panes 0))
      (camera.ensure-panes-ahead! state (* c.PANE_W 1.5))
      (assert-is (. state.panes 1))
      (assert-is (. state.panes 2)))))

(deftest world-min-x-advances-test
  (testing "world-min-x tracks camera forward"
    (let [state (camera.initial-state)]
      (camera.update-camera! state 100)
      (assert-eq 0 state.world-min-x)
      (camera.update-camera! state 500)
      (assert-is (>= state.world-min-x 200))
      (assert-eq state.camera-x state.world-min-x))))

(deftest clamp-player-x-test
  (testing "player cannot move left of world-min-x"
    (assert-eq 100 (camera.clamp-player-x 50 100))
    (assert-eq 150 (camera.clamp-player-x 150 100))))

(deftest unload-old-panes-test
  (testing "panes behind world-min-x are discarded"
    (math.randomseed 11)
    (let [state (camera.initial-state)]
      (camera.ensure-panes-ahead! state 0)
      (camera.ensure-panes-ahead! state (* c.PANE_W 3))
      (tset state :world-min-x (* c.PANE_W 2))
      (camera.unload-old-panes! state)
      (assert-is (not (. state.panes 0)))
      (assert-is (not (. state.panes 1)))
      (assert-is (. state.panes 2)))))
