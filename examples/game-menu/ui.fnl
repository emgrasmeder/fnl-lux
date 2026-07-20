(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local systems (require :systems))

(fn entity-components [world entity-id]
  (get-table-by-id world entity-id))

(fn render-button [world entity-id highlighted?]
  (let [components (entity-components world entity-id)]
    (when components
      (let [[x y w h] components.button
            label (. components.label 1)]
        (if highlighted?
            (love.graphics.setColor 0.35 0.35 0.45 1)
            (love.graphics.setColor 0.2 0.2 0.25 1))
        (love.graphics.rectangle "fill" x y w h)
        (love.graphics.setColor 0.9 0.9 0.95 1)
        (love.graphics.rectangle "line" x y w h)
        (let [font (love.graphics.getFont)
              text-width (font:getWidth label)
              text-height (font:getHeight)]
          (love.graphics.print label
                               (+ x (/ (- w text-width) 2))
                               (+ y (/ (- h text-height) 2))))))))

(fn render-menu [menu focused-index]
  (let [world menu.world
        button-ids menu.button-ids
        (mx my) (love.mouse.getPosition)
        hover-id (systems.hit-test-at menu mx my)]
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print "Game Menu" 20 20)
    (for [i 1 (# button-ids)]
      (let [entity-id (. button-ids i)
            highlighted? (or (= i focused-index) (= entity-id hover-id))]
        (render-button world entity-id highlighted?)))))

{:render-menu render-menu}
