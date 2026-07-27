(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))

(var game nil)
(var state nil)

(fn reset-game! []
  (math.randomseed (os.time))
  (set game (world-mod.create-game-world))
  (set state (systems.initial-state game)))

(fn love.load []
  (reset-game!))

(fn love.update [dt]
  (systems.step game state dt))

(fn love.draw []
  (ui.render game state))

(fn love.keypressed [key]
  (when (= (systems.on-key game state key) :restart)
    (reset-game!)))
