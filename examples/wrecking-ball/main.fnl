(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))

(var sim-game nil)
(var sim nil)

(fn reset-game! []
  (math.randomseed (os.time))
  (set sim-game (world-mod.create-game-world))
  (set sim (systems.initial-state)))

(fn love.load []
  (reset-game!))

(fn love.update [dt]
  (systems.step sim-game sim dt))

(fn love.draw []
  (ui.render sim-game sim))

(fn love.keypressed [key]
  (systems.on-key sim key))
