(fn clear-background []
  (love.graphics.clear 0.08 0.08 0.1 1))

(fn render-line-grid [ox oy grid-w grid-h cell-size]
  (let [board-w (* grid-w cell-size)
        board-h (* grid-h cell-size)]
    (love.graphics.setColor 0.9 0.9 0.95 1)
    (for [col 0 grid-w]
      (love.graphics.line (+ ox (* col cell-size)) oy
                          (+ ox (* col cell-size)) (+ oy board-h)))
    (for [row 0 grid-h]
      (love.graphics.line ox (+ oy (* row cell-size))
                          (+ ox board-w) (+ oy (* row cell-size))))))

(fn render-tic-tac-toe-grid [ox oy cell-size]
  (let [board-size (* 3 cell-size)]
    (love.graphics.setColor 0.9 0.9 0.95 1)
    (love.graphics.rectangle "line" ox oy board-size board-size)
    (for [i 1 2]
      (let [offset (* i cell-size)]
        (love.graphics.line (+ ox offset) oy (+ ox offset) (+ oy board-size))
        (love.graphics.line ox (+ oy offset) (+ ox board-size) (+ oy offset))))))

(fn fill-rect [mode x y w h]
  (love.graphics.rectangle mode x y w h))

(fn fill-rects [rects]
  (each [_ rect (ipairs rects)]
    (let [[x y w h] rect]
      (fill-rect "fill" x y w h))))

(fn print-centered-in-rect [text x y w h]
  (let [font (love.graphics.getFont)
        text-width (font:getWidth text)
        text-height (font:getHeight)]
    (love.graphics.print text
                         (+ x (/ (- w text-width) 2))
                         (+ y (/ (- h text-height) 2)))))

(fn render-message-overlay [text]
  (let [font (love.graphics.getFont)
        text-width (font:getWidth text)
        text-height (font:getHeight)
        screen-w (love.graphics.getWidth)
        screen-h (love.graphics.getHeight)]
    (love.graphics.setColor 0 0 0 0.5)
    (love.graphics.rectangle "fill" 0 0 screen-w screen-h)
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print text
                         (/ (- screen-w text-width) 2)
                         (/ (- screen-h text-height) 2))))

(fn render-stick-figure [feet-x feet-y height]
  (let [leg-len (* height 0.22)
        body-len (* height 0.28)
        arm-len (* height 0.2)
        head-r (* height 0.12)
        hip-y (- feet-y leg-len)
        shoulder-y (- hip-y body-len)
        head-cy (- shoulder-y head-r)
        arm-spread (* arm-len 0.85)
        leg-spread (* leg-len 0.55)]
    (love.graphics.line feet-x feet-y (- feet-x leg-spread) feet-y)
    (love.graphics.line feet-x feet-y (+ feet-x leg-spread) feet-y)
    (love.graphics.line feet-x hip-y feet-x shoulder-y)
    (love.graphics.line feet-x shoulder-y (- feet-x arm-spread) (+ shoulder-y (* body-len 0.35)))
    (love.graphics.line feet-x shoulder-y (+ feet-x arm-spread) (+ shoulder-y (* body-len 0.35)))
    (love.graphics.circle "line" feet-x head-cy head-r)))

{:clear-background clear-background
 :render-line-grid render-line-grid
 :render-tic-tac-toe-grid render-tic-tac-toe-grid
 :fill-rect fill-rect
 :fill-rects fill-rects
 :print-centered-in-rect print-centered-in-rect
 :render-message-overlay render-message-overlay
 :render-stick-figure render-stick-figure}
