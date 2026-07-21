(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))

(var game nil)
(var state nil)

(fn reset-game! []
  (math.randomseed (os.time))
  (set game (world-mod.create-game-world))
  (set state {:current-player (systems.pick-first-player)
              :phase :playing
              :message nil}))

(fn love.load []
  (reset-game!))

(fn love.draw []
  (ui.render game state))

(fn love.mousepressed [mx my button]
  (when (and (= button 1) (= state.phase :playing))
    (let [outcome (systems.handle-click game state mx my)]
      (when outcome
        (case (. outcome :result)
          :win (set state {:phase :ended
                           :message (.. (systems.player-label (. outcome :winner)) " wins!")
                           :current-player (. outcome :winner)})
          :draw (set state {:phase :ended
                            :message "Draw!"
                            :current-player state.current-player})
          :continue (tset state :current-player (. outcome :next-player)))))))

(fn love.keypressed [key]
  (when (and (= key "r") (= state.phase :ended))
    (reset-game!)))
