(fn fixture-filename [name]
  (.. name ".png"))

(fn fixture-rel-path [name]
  (.. "fixtures/" (fixture-filename name)))

(fn fixture-source-path [name]
  (.. (love.filesystem.getSource) "/" (fixture-rel-path name)))

(fn load-fixture-image [name]
  (love.image.newImageData (fixture-rel-path name)))

(fn image-data-equal? [actual expected name]
  (let [w (actual:getWidth)
        h (actual:getHeight)
        ew (expected:getWidth)
        eh (expected:getHeight)]
    (when (not= w ew)
      (error (.. "fixture " name ": width " w " vs golden " ew)))
    (when (not= h eh)
      (error (.. "fixture " name ": height " h " vs golden " eh)))
    (for [y 0 (- h 1)]
      (for [x 0 (- w 1)]
        (let [(r1 g1 b1 a1) (actual:getPixel x y)
              (r2 g2 b2 a2) (expected:getPixel x y)]
          (when (or (not= r1 r2) (not= g1 g2) (not= b1 b2) (not= a1 a2))
            (error (.. "fixture " name ": pixel mismatch at " x "," y
                       " got " r1 "," g1 "," b1 "," a1
                       " expected " r2 "," g2 "," b2 "," a2))))))))

(fn save-fixture! [image-data name]
  (let [dir (.. (love.filesystem.getSource) "/fixtures")
        path (fixture-source-path name)
        file-data (image-data:encode "png")]
    (os.execute (.. "mkdir -p " (string.format "%q" dir)))
    (with-open [f (assert (io.open path "wb"))]
      (f:write (file-data:getString)))))

{:load-fixture-image load-fixture-image
 :image-data-equal? image-data-equal?
 :save-fixture! save-fixture!}
