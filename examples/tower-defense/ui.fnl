(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local world-mod (require :world))
(local systems (require :systems))
(local love-ui (require :shared.love-ui))
(local creep-draw (require :creep-draw))
(local bullet-draw (require :bullet-draw))

(fn render-terrain [game]
  (for [row 1 game.grid-h]
    (for [col 1 game.grid-w]
      (let [kind (. game.terrain (world-mod.cell-key row col))
            [x y w h] (world-mod.cell-bounds-at row col)]
        (case kind
          :wall (do
                  (love.graphics.setColor 0.35 0.35 0.45 1)
                  (love-ui.fill-rect "fill" x y w h))
          :tower (do
                   (love.graphics.setColor 0.55 0.35 0.2 1)
                   (love-ui.fill-rect "fill" x y w h))
          ;; openings match neutral background — leave unfilled
          _ nil)))))

(fn render-creeps [game state]
  (each [_ id (ipairs state.creep-ids)]
    (let [components (get-table-by-id game.world id)]
      (when components
        (let [x (. components.position 1)
              y (. components.position 2)
              creep-data (. state.creep-paths id)
              phase (or (and creep-data (. creep-data :walk-phase)) 0)]
          (creep-draw.render-creep! x y world-mod.CREEP-DRAW-RADIUS phase))))))

(fn render-bullets [game state]
  (each [_ id (ipairs (or state.bullet-ids []))]
    (let [components (get-table-by-id game.world id)]
      (when components
        (bullet-draw.render-bullet! (. components.position 1)
                                    (. components.position 2)
                                    world-mod.BULLET-RADIUS)))))

(fn render-hud [state]
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print (.. "Budget: " (or state.budget 0)) 8 8)
  (love.graphics.print (.. "Escapes: " state.escapes "/" world-mod.MAX-ESCAPES) 8 24)
  (love.graphics.print (.. "Wave: " state.wave-index "/" (systems.wave-count)) 8 40)
  (love.graphics.print (.. "Creeps: " (# state.creep-ids)) 8 56)
  (love.graphics.print (.. "Kills: " (or state.kills 0)) 8 72))

(fn render-button [label x y w h enabled?]
  (if enabled?
      (love.graphics.setColor 0.25 0.45 0.7 1)
      (love.graphics.setColor 0.25 0.25 0.3 1))
  (love-ui.fill-rect "fill" x y w h)
  (love.graphics.setColor 1 1 1 1)
  (love-ui.print-centered-in-rect label x y w h))

(fn render-bottom-bar [state]
  (let [[px py pw ph] (world-mod.play-button-rect)
        [sx sy sw sh] (world-mod.stats-button-rect)]
    (render-button "Play" px py pw ph (= state.phase :building))
    (render-button "Stats" sx sy sw sh true)))

(fn render-stats-overlay [game state]
  (when state.stats-open
    (let [[px py pw ph] (world-mod.stats-panel-rect)
          kills (or state.kills 0)
          towers (systems.towers-built game)
          line1 (.. "Budget: " (or state.budget 0))
          line2 (.. "Kills: " kills)
          line3 (.. "Towers: " towers)
          line4 (.. "Escapes: " state.escapes "/" world-mod.MAX-ESCAPES)
          screen-w (world-mod.window-width)
          screen-h (world-mod.window-height)]
      (love.graphics.setColor 0 0 0 0.5)
      (love.graphics.rectangle "fill" 0 0 screen-w screen-h)
      (love.graphics.setColor 0.12 0.12 0.16 1)
      (love-ui.fill-rect "fill" px py pw ph)
      (love.graphics.setColor 1 1 1 1)
      (love.graphics.print line1 (+ px 16) (+ py 14))
      (love.graphics.print line2 (+ px 16) (+ py 36))
      (love.graphics.print line3 (+ px 16) (+ py 58))
      (love.graphics.print line4 (+ px 16) (+ py 80)))))

(fn render [game state]
  (love-ui.clear-background)
  (render-terrain game)
  (love-ui.render-line-grid world-mod.BOARD-OX world-mod.BOARD-OY
                            world-mod.GRID-W world-mod.GRID-H world-mod.CELL-SIZE)
  (render-creeps game state)
  (render-bullets game state)
  (render-hud state)
  (render-bottom-bar state)
  (let [text (systems.overlay-text state)]
    (when (and text (not state.stats-open))
      (love-ui.render-message-overlay text)))
  (render-stats-overlay game state))

{:render render}
