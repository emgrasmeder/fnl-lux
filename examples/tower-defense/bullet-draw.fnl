(fn render-bullet! [x y radius]
  (love.graphics.setColor 0.95 0.9 0.4 1)
  (love.graphics.circle "fill" x y radius))

{:render-bullet! render-bullet!}
